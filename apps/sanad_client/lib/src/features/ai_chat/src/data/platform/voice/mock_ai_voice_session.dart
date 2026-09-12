import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/audio/audio_session_manager.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/audio/wav_header.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/voice/mock_voice_scenarios.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_voice_event.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/enums/ai_voice_session_status.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_audio_player.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_voice_capture.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_voice_session.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/usecases/audio_level_scale.dart';

/// The thresholds and delays that shape the mocked conversation.
///
/// Injectable so the state machine can be driven deterministically in a test —
/// synthetic loud and quiet frames, zero delays, no real time passing. Numbers
/// buried in the implementation would make every one of those tests a
/// stopwatch race.
final class AiVoiceTuning {
  /// Creates a tuning.
  const AiVoiceTuning({
    this.connectDelay = const Duration(milliseconds: 600),
    this.processingDelay = const Duration(milliseconds: 900),
    this.speechThreshold = 0.06,
    this.silenceHold = const Duration(milliseconds: 1200),
    this.minUtterance = const Duration(milliseconds: 400),
    this.bargeInThreshold = 0.35,
    this.bargeInGrace = const Duration(milliseconds: 800),
  });

  /// How long "connecting" is shown before listening starts.
  final Duration connectDelay;

  /// How long the assistant appears to think.
  final Duration processingDelay;

  /// RMS above which a frame counts as speech rather than room tone.
  final double speechThreshold;

  /// How long the user must stay quiet, after speaking, to end their turn.
  final Duration silenceHold;

  /// The shortest utterance worth replying to, so a cough is not a turn.
  final Duration minUtterance;

  /// RMS that interrupts the assistant mid-reply.
  ///
  /// Higher than [speechThreshold] because the microphone is still open while
  /// the assistant speaks and will hear some of it, echo cancellation or not.
  final double bargeInThreshold;

  /// How long after the assistant starts talking before barge-in can fire, so
  /// the first syllable of the reply cannot interrupt itself.
  final Duration bargeInGrace;
}

/// A live-voice session with a **real microphone** and a mocked assistant.
///
/// ## What is real and what is not
///
/// Real: the permission, the microphone, the PCM frames, the loudness meter,
/// the silence detection, the audio session and its interruptions, the file
/// written to disk, and the playback. Mocked: only what the assistant *says* —
/// which is the captured audio played back.
///
/// Echoing the capture is deliberate. A bundled clip would sound more like a
/// real assistant while proving less: it would leave capture and playback
/// unconnected, so a broken microphone would still produce a convincing demo.
/// Playing back what was just recorded cannot pass unless the whole loop works.
///
/// ## Why no `Timer` in the UI
///
/// Silence is detected from the frame stream itself — the frames *are* the
/// clock. Only the two deliberate theatrical pauses (connecting, thinking) use
/// a timer, they live here in the data layer, and both are cancelled on
/// [dispose] with their futures completed so nothing is left awaiting.
class MockAiVoiceSession implements AiVoiceSession {
  /// Creates the session.
  MockAiVoiceSession({
    required AiVoiceCapture capture,
    required AiAudioPlayer player,
    required AudioSessionManager session,
    this.tuning = const AiVoiceTuning(),
    this.uiScript,
  }) : _capture = capture,
       _player = player,
       _session = session {
    _playerSubscription = _player.progress.listen(_onPlaybackProgress);
    _sessionSubscription = _session.events.listen(_onSessionEvent);
  }

  /// The thresholds and delays in use.
  final AiVoiceTuning tuning;

  /// When the assistant asks a card instead of talking.
  ///
  /// `null` — the default — is the echo-only session this mock has always
  /// been, which is what keeps every existing test exercising the same state
  /// machine it was written against.
  final AiVoiceUiScript? uiScript;

  final AiVoiceCapture _capture;
  final AiAudioPlayer _player;
  final AudioSessionManager _session;

  final StreamController<AiVoiceSessionStatus> _status =
      StreamController<AiVoiceSessionStatus>.broadcast();
  final StreamController<double> _level = StreamController<double>.broadcast();
  final StreamController<AiVoiceEvent> _events =
      StreamController<AiVoiceEvent>.broadcast();

  StreamSubscription<Uint8List>? _frameSubscription;
  StreamSubscription<AiPlaybackProgress>? _playerSubscription;
  StreamSubscription<AudioSessionEvent>? _sessionSubscription;

  /// Every pending theatrical pause, so `dispose` can cancel the timer *and*
  /// complete its future — cancelling alone would leave an `await` hanging
  /// forever. The same discipline `MockAiChatEventSource` uses.
  final Map<Timer, Completer<void>> _pending = {};

  AiVoiceSessionStatus _current = AiVoiceSessionStatus.idle;
  String? _failureKey;
  bool _muted = false;

  /// The previously drawn level, so falling silent decays rather than snaps.
  double _displayLevel = 0;
  bool _disposed = false;

  IOSink? _sink;
  String? _utterancePath;
  int _utteranceBytes = 0;
  DateTime? _utteranceStartedAt;
  DateTime? _lastLoudAt;
  DateTime? _speakingSince;
  bool _heardSpeech = false;
  bool _wasPlaying = false;
  int _takeCounter = 0;

  /// The recording held back while a card is on screen.
  ///
  /// The assistant's "reply" is the user's own audio, and it must survive the
  /// pause: playing it before the card is answered would talk over the
  /// question, and dropping it would leave the session silent afterwards.
  String? _heldTakePath;

  /// How many turns the user has taken, which is what the script is indexed
  /// by.
  int _turnCounter = 0;

  @override
  Stream<AiVoiceSessionStatus> get status => _status.stream;

  @override
  Stream<double> get inputLevel => _level.stream;

  @override
  Stream<AiVoiceEvent> get events => _events.stream;

  @override
  String? get failureKey => _failureKey;

  @override
  Future<void> start() async {
    if (_disposed || _current.isActive) return;

    _failureKey = null;
    _emitStatus(AiVoiceSessionStatus.connecting);

    if (!await _capture.isAvailable) {
      _fail('ai_chat.voice_microphone_unavailable');
      return;
    }

    // Recording mode for the whole session, not just the listening half: the
    // microphone stays open while the assistant speaks so the user can barge
    // in, so the category must permit capture throughout.
    if (!await _session.activate(AudioSessionMode.recording)) {
      _fail('ai_chat.voice_microphone_unavailable');
      return;
    }
    await _wait(tuning.connectDelay);
    if (_disposed || _current != AiVoiceSessionStatus.connecting) return;

    try {
      final frames = await _capture.start();
      _frameSubscription = frames.listen(
        _onFrame,
        onError: (_) => _fail('ai_chat.voice_error'),
      );
    } on Object {
      _fail('ai_chat.voice_error');
      return;
    }

    await _beginListening();
  }

  @override
  Future<void> setMuted({required bool muted}) async {
    // The microphone stays open while muted — dropping the stream and
    // reopening it costs a permission round trip on some platforms and makes
    // unmuting feel broken. Frames are simply not recorded or measured.
    _muted = muted;
    if (muted) {
      _displayLevel = 0;
      _emitLevel(0);
    }
  }

  /// Ends the user's turn on request instead of waiting for silence.
  ///
  /// Normally [_endUtterance] fires from the microphone frames themselves —
  /// `silenceHold` of quiet after some speech. Tapping the button says the
  /// same thing earlier, so it runs the identical path rather than a parallel
  /// one: same guard, same utterance close, same processing → speaking flow.
  ///
  /// No cancellation is needed first, because nothing is scheduled — the
  /// frames are the clock. The guard inside [_endUtterance] makes a second
  /// tap a no-op.
  @override
  Future<void> finishTurn() async {
    if (_disposed || _current != AiVoiceSessionStatus.listening) return;
    await _endUtterance();
  }

  @override
  Future<void> interrupt() async {
    if (_current != AiVoiceSessionStatus.speaking) return;
    await _player.stop();
    await _beginListening();
  }

  @override
  Future<void> end() async {
    if (_disposed || _current.isTerminal) return;

    // A card on screen when the session ends is taken down rather than left
    // waiting for an answer nothing will ever receive.
    if (_current == AiVoiceSessionStatus.awaitingInteraction) {
      _events.add(const AiVoiceUiResolved());
    }
    _heldTakePath = null;

    _emitStatus(AiVoiceSessionStatus.ending);
    await _teardownAudio();
    _emitStatus(AiVoiceSessionStatus.ended);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    // Complete every pending pause so anything awaiting one resumes, sees
    // `_disposed` and stops, rather than being stranded.
    for (final entry in _pending.entries) {
      entry.key.cancel();
      if (!entry.value.isCompleted) entry.value.complete();
    }
    _pending.clear();

    await _playerSubscription?.cancel();
    await _sessionSubscription?.cancel();
    _playerSubscription = null;
    _sessionSubscription = null;

    await _teardownAudio();
    await _capture.dispose();

    if (!_status.isClosed) await _status.close();
    if (!_level.isClosed) await _level.close();
    if (!_events.isClosed) await _events.close();
  }

  // ── the listening/speaking cycle ──────────────────────────────────────────

  Future<void> _beginListening() async {
    if (_disposed) return;

    await _openUtterance();
    _heardSpeech = false;
    _lastLoudAt = null;
    _speakingSince = null;
    _wasPlaying = false;
    _emitStatus(AiVoiceSessionStatus.listening);
  }

  void _onFrame(Uint8List frame) {
    if (_disposed || _muted) return;

    // Two different numbers on purpose. `rms` is the raw linear loudness the
    // detectors are tuned against — `speechThreshold` and `bargeInThreshold`
    // are calibrated in those units and must keep seeing them. What the meter
    // draws is a different question: speech RMS sits around 0.02 to 0.10, so a
    // meter fed the raw value would never leave the bottom tenth of its travel
    // however loudly anyone spoke.
    final rms = WavHeader.rms(frame);
    _displayLevel = AudioLevelScale.release(
      _displayLevel,
      AudioLevelScale.fromLinear(rms),
    );
    _emitLevel(_displayLevel);

    switch (_current) {
      case AiVoiceSessionStatus.listening:
        _recordFrame(frame, rms);
      case AiVoiceSessionStatus.speaking:
        _maybeBargeIn(rms);
      // Frames still arrive while a card is up — the capture stream is not
      // torn down for a pause measured in seconds — but nothing acts on them.
      // That is the whole reason `awaitingInteraction` exists: silence
      // detection and barge-in must not race a user reading a question.
      case AiVoiceSessionStatus.awaitingInteraction:
      case AiVoiceSessionStatus.idle:
      case AiVoiceSessionStatus.connecting:
      case AiVoiceSessionStatus.processing:
      case AiVoiceSessionStatus.ending:
      case AiVoiceSessionStatus.ended:
      case AiVoiceSessionStatus.error:
        break;
    }
  }

  void _recordFrame(Uint8List frame, double level) {
    // Straight to the file sink. Buffering the whole utterance in memory would
    // be megabytes of PCM held for no reason — the file is the buffer.
    _sink?.add(frame);
    _utteranceBytes += frame.lengthInBytes;

    final now = DateTime.now();
    if (level >= tuning.speechThreshold) {
      _heardSpeech = true;
      _lastLoudAt = now;
      return;
    }

    // The frames are the clock: no timer decides when someone stopped talking.
    final lastLoudAt = _lastLoudAt;
    final startedAt = _utteranceStartedAt;
    if (!_heardSpeech || lastLoudAt == null || startedAt == null) return;
    if (now.difference(lastLoudAt) < tuning.silenceHold) return;
    if (now.difference(startedAt) < tuning.minUtterance) return;

    unawaited(_endUtterance());
  }

  void _maybeBargeIn(double level) {
    final since = _speakingSince;
    if (since == null) return;
    if (DateTime.now().difference(since) < tuning.bargeInGrace) return;
    if (level < tuning.bargeInThreshold) return;

    unawaited(interrupt());
  }

  Future<void> _endUtterance() async {
    if (_disposed || _current != AiVoiceSessionStatus.listening) return;

    _emitStatus(AiVoiceSessionStatus.processing);
    final path = await _closeUtterance();

    await _wait(tuning.processingDelay);
    if (_disposed || _current != AiVoiceSessionStatus.processing) return;

    if (path == null) {
      await _beginListening();
      return;
    }

    _turnCounter++;
    final payload = uiScript?.call(_turnCounter);
    if (payload != null) {
      // The reply waits its turn: the card is the question, and answering it
      // is what resumes the conversation. See [submitInteraction].
      _heldTakePath = path;
      _events.add(AiVoiceUiRequested(payload));
      _emitStatus(AiVoiceSessionStatus.awaitingInteraction);
      return;
    }

    _speak(path);
  }

  /// Plays [path] as the assistant's reply.
  void _speak(String path) {
    _emitStatus(AiVoiceSessionStatus.speaking);
    _speakingSince = DateTime.now();
    _wasPlaying = false;

    _player
        .play(id: 'voice_$_takeCounter', path: path)
        .onError<Object>((_, _) => _fail('ai_chat.voice_error'));
  }

  /// Resumes the conversation once the user answers the card.
  ///
  /// Idempotent and state-guarded: a late answer — the ledger let one through
  /// just as the session ended, or a duplicate arrived from a rebuild — is
  /// ignored rather than treated as an error.
  @override
  Future<void> submitInteraction(AiUiInteraction interaction) async {
    if (_disposed || _current != AiVoiceSessionStatus.awaitingInteraction) {
      return;
    }

    _events.add(AiVoiceUiResolved(interaction.nodeId));
    _emitStatus(AiVoiceSessionStatus.processing);

    // A real agent would answer *about* the interaction. The mock cannot say
    // anything it was not given, so it resumes the reply it was holding —
    // which still proves the sequencing: the card gated the audio, and the
    // answer released it.
    await _wait(tuning.processingDelay);
    if (_disposed || _current != AiVoiceSessionStatus.processing) return;

    final path = _heldTakePath;
    _heldTakePath = null;
    if (path == null) {
      await _beginListening();
      return;
    }

    _speak(path);
  }

  void _onPlaybackProgress(AiPlaybackProgress progress) {
    if (_current != AiVoiceSessionStatus.speaking) return;

    if (progress.isPlaying) {
      _wasPlaying = true;
      return;
    }
    // Playing then not playing means the reply finished; hand the turn back.
    if (_wasPlaying) unawaited(_beginListening());
  }

  // ── utterance file plumbing ───────────────────────────────────────────────

  Future<void> _openUtterance() async {
    await _closeUtterance();

    final directory = await getTemporaryDirectory();
    _takeCounter++;
    final path = '${directory.path}/ai_voice_$_takeCounter.wav';
    final file = File(path);

    // A placeholder header first, rewritten with the real length on close —
    // the payload size is not knowable until the user stops talking.
    _sink = file.openWrite()
      ..add(
        WavHeader.build(
          dataBytes: 0,
          sampleRate: AiVoiceAudioFormat.sampleRate,
          channels: AiVoiceAudioFormat.channels,
          bitsPerSample: AiVoiceAudioFormat.bitsPerSample,
        ),
      );

    _utterancePath = path;
    _utteranceBytes = 0;
    _utteranceStartedAt = DateTime.now();
  }

  /// Finalises the current utterance and returns its playable path.
  Future<String?> _closeUtterance() async {
    final sink = _sink;
    final path = _utterancePath;
    _sink = null;
    _utterancePath = null;
    _utteranceStartedAt = null;

    if (sink == null || path == null) return null;

    try {
      await sink.flush();
      await sink.close();
    } on Object {
      return null;
    }

    if (_utteranceBytes == 0) {
      await _deleteQuietly(path);
      return null;
    }

    try {
      // Patch the two length fields in place rather than rewriting the file.
      final handle = await File(path).open(mode: FileMode.append);
      final header = WavHeader.build(
        dataBytes: _utteranceBytes,
        sampleRate: AiVoiceAudioFormat.sampleRate,
        channels: AiVoiceAudioFormat.channels,
        bitsPerSample: AiVoiceAudioFormat.bitsPerSample,
      );
      await handle.setPosition(0);
      await handle.writeFrom(header);
      await handle.close();
    } on Object {
      await _deleteQuietly(path);
      return null;
    }

    return path;
  }

  Future<void> _teardownAudio() async {
    await _frameSubscription?.cancel();
    _frameSubscription = null;

    await _capture.stop();
    await _player.stop();

    // Every utterance file is scratch; none of them becomes a message.
    final path = await _closeUtterance();
    if (path != null) await _deleteQuietly(path);
    for (var i = 1; i <= _takeCounter; i++) {
      final directory = await getTemporaryDirectory();
      await _deleteQuietly('${directory.path}/ai_voice_$i.wav');
    }

    await _session.deactivate();
    _emitLevel(0);
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } on Object {
      // A scratch file we cannot remove is not worth failing teardown over.
    }
  }

  // ── plumbing ──────────────────────────────────────────────────────────────

  void _onSessionEvent(AudioSessionEvent event) {
    if (!_current.isActive) return;
    switch (event) {
      // A real external interruption — a call, another app taking the audio
      // path. The session cannot continue through it.
      case AudioSessionEvent.interrupted:
        unawaited(end());
      // Headphones pulled out. The reply is about to come from the speaker
      // instead, which is a routing change, not a reason to hang up mid
      // sentence. `just_audio` pauses playback on this signal itself.
      case AudioSessionEvent.becameNoisy:
      // A request to be quieter, which a duplex session does not honour by
      // ending.
      case AudioSessionEvent.ducked:
      case AudioSessionEvent.resumed:
        break;
    }
  }

  void _fail(String failureKey) {
    _failureKey = failureKey;
    unawaited(_teardownAudio());
    _emitStatus(AiVoiceSessionStatus.error);
  }

  void _emitStatus(AiVoiceSessionStatus status) {
    if (_disposed || _status.isClosed) return;
    _current = status;
    _status.add(status);
  }

  void _emitLevel(double level) {
    if (_disposed || _level.isClosed) return;
    _level.add(level);
  }

  /// A cancellable pause. See [_pending] for why the completer matters.
  Future<void> _wait(Duration duration) {
    if (duration == Duration.zero) return Future<void>.value();

    final completer = Completer<void>();
    late final Timer timer;
    timer = Timer(duration, () {
      _pending.remove(timer);
      if (!completer.isCompleted) completer.complete();
    });
    _pending[timer] = completer;
    return completer.future;
  }
}
