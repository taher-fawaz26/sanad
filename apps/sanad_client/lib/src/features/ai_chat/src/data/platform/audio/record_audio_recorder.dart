import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/audio/audio_session_manager.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_audio_recorder.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/usecases/audio_level_scale.dart';

/// Records a voice note with the device microphone.
///
/// The only file in the feature that names `record`. Everything above it sees
/// [AiAudioRecorder], which is why the composer bloc's whole state machine is
/// testable with no microphone.
///
/// ## Encoding, and why these numbers
///
/// AAC-LC mono at 32 kbps / 22.05 kHz is roughly 4 KB per second. A voice note
/// is speech, not music, so the bitrate that matters is intelligibility — and
/// the low rate is what keeps a five-minute take near 1.2 MB, comfortably
/// inside the repo-wide 5 MiB `FileSizePolicy` ceiling. Recording at the
/// plugin's 128 kbps stereo default would put a four-minute take over the
/// limit and the user would only find out after speaking.
///
/// ## No timer
///
/// Elapsed time is derived from the amplitude stream, which already ticks at
/// [_amplitudeInterval]. The maximum duration is enforced by the composer bloc
/// reacting to that same tick. There is no `Timer` here or anywhere above.
///
/// ## Who owns audio focus
///
/// [AudioSessionManager] does, exclusively — see [recordingConfig].
class RecordAudioRecorder implements AiAudioRecorder {
  /// Creates the recorder.
  ///
  /// [session] is shared with playback so focus is handed back and forth
  /// rather than fought over.
  RecordAudioRecorder({required AudioSessionManager session})
    : _session = session {
    _sessionSubscription = _session.events.listen(_onSessionEvent);
  }

  /// How often the platform reports loudness. Fast enough for a waveform to
  /// look live, slow enough not to wake the UI thread pointlessly.
  static const Duration _amplitudeInterval = Duration(milliseconds: 120);

  /// How a take is captured.
  ///
  /// `audioInterruption: none` is the load-bearing line, and it is about audio
  /// *focus*, not about ignoring interruptions. `record` defaults to
  /// [AudioInterruptionMode.pause], which makes its Android recorder request
  /// `AUDIOFOCUS_GAIN` of its own the moment capture starts. Android's focus
  /// stack is keyed by listener rather than by process, so that second request
  /// evicts [AudioSessionManager]'s — which had just been granted a line
  /// earlier — and delivers it `onAudioFocusChange(-1)`. `audio_session`
  /// reports that as a beginning interruption, and the take died of an
  /// interruption it had caused itself, roughly 100 ms after it started.
  ///
  /// With `none`, `record` requests no focus at all and this feature keeps
  /// exactly one focus client. Interruption handling is not lost: it moves to
  /// where it was always meant to live, in [AudioSessionManager.events] and
  /// [abortFor] below, where a real call still ends the take.
  ///
  /// Exposed so a test can assert the setting without a microphone; it is the
  /// single value that separates a working recorder from a self-cancelling one.
  static const RecordConfig recordingConfig = RecordConfig(
    // Named even though it is the plugin default: the codec is half the
    // reason the bitrate below is safe, and a default that changed
    // underneath us would silently blow the size ceiling.
    // ignore: avoid_redundant_argument_values
    encoder: AudioEncoder.aacLc,
    bitRate: 32000,
    sampleRate: 22050,
    numChannels: 1,
    audioInterruption: AudioInterruptionMode.none,
  );

  final AudioSessionManager _session;
  final AudioRecorder _recorder = AudioRecorder();

  final StreamController<AiRecordingSample> _samples =
      StreamController<AiRecordingSample>.broadcast();
  final StreamController<AiRecordingAbort> _aborts =
      StreamController<AiRecordingAbort>.broadcast();

  StreamSubscription<Amplitude>? _amplitudeSubscription;
  StreamSubscription<AudioSessionEvent>? _sessionSubscription;

  DateTime? _startedAt;
  Duration _maxDuration = Duration.zero;

  /// The previous displayed level, so a falling reading decays rather than
  /// snapping. Reset per take.
  double _level = 0;
  String? _path;
  bool _disposed = false;

  @override
  Stream<AiRecordingSample> get samples => _samples.stream;

  @override
  Stream<AiRecordingAbort> get aborts => _aborts.stream;

  @override
  Future<bool> get isAvailable async {
    if (_disposed) return false;
    try {
      // `request: false` so a capability probe never raises a permission
      // prompt — asking is the gateway's job, not the recorder's.
      return await _recorder.hasPermission(request: false) ||
          await _recorder.isEncoderSupported(AudioEncoder.aacLc);
    } on Object {
      return false;
    }
  }

  @override
  Future<void> start({required Duration maxDuration}) async {
    if (_disposed) return;

    // Configure for capture, then take focus, then open the microphone — in
    // that order. Reversing the first two would ask the OS to record under a
    // playback category, which iOS refuses outright.
    if (!await _session.activate(AudioSessionMode.recording)) {
      // Focus is refused during a call. Opening the microphone anyway would
      // capture into a session the OS has already given to someone else.
      throw StateError('audio focus denied');
    }

    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/ai_chat_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(recordingConfig, path: path);

    _path = path;
    _maxDuration = maxDuration;
    _startedAt = DateTime.now();
    _level = 0;

    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = _recorder
        .onAmplitudeChanged(_amplitudeInterval)
        .listen(_onAmplitude, onError: (_) => _abort(AiRecordingAbort.failed));
  }

  @override
  Future<String?> stop() async {
    if (_disposed) return null;

    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    _startedAt = null;

    final path = await _recorder.stop();
    await _session.deactivate();
    _path = null;
    return path;
  }

  @override
  Future<void> cancel() async {
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    _startedAt = null;

    final path = _path;
    _path = null;

    try {
      await _recorder.cancel();
    } on Object {
      // Cancelling something that was never started is not an error.
    }
    await _session.deactivate();

    // `cancel()` is documented to delete the file, but a partial take left on
    // disk after an interrupted session is exactly the kind of leak that only
    // shows up as a full device weeks later.
    if (path != null) await discard(path);
  }

  @override
  Future<void> discard(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } on Object {
      // A file that is already gone, or that the OS will not let us remove,
      // is not worth failing a teardown over.
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    await _amplitudeSubscription?.cancel();
    await _sessionSubscription?.cancel();
    _amplitudeSubscription = null;
    _sessionSubscription = null;

    // Disposing mid-take must not leave the microphone held or the partial
    // file behind.
    final path = _path;
    _path = null;
    try {
      await _recorder.cancel();
    } on Object {
      // Nothing was running.
    }
    if (path != null) await discard(path);

    await _recorder.dispose();
    await _session.deactivate();

    if (!_samples.isClosed) await _samples.close();
    if (!_aborts.isClosed) await _aborts.close();
  }

  void _onAmplitude(Amplitude amplitude) {
    final startedAt = _startedAt;
    if (_disposed || startedAt == null || _samples.isClosed) return;

    // Clamped at the cap so the reported elapsed can never run past it. The
    // composer stops the take on this same value, so the two agree by
    // construction rather than by two clocks happening to line up.
    final elapsed = DateTime.now().difference(startedAt);

    // `Amplitude.current` is a **peak** sample in dBFS — verified on device:
    // `record` computes `20*log10(peak / 32767)` and floors at -160. It is not
    // normalised, so the mapping and the release curve both belong here, in
    // domain arithmetic the meter simply draws.
    _level = AudioLevelScale.release(
      _level,
      AudioLevelScale.fromDbfs(amplitude.current),
    );

    _samples.add(
      AiRecordingSample(
        level: _level,
        elapsed: elapsed > _maxDuration ? _maxDuration : elapsed,
      ),
    );
  }

  /// Whether a session event should end a live take, and why.
  ///
  /// Pure and static so the classification is assertable without a microphone.
  ///
  /// Only [AudioSessionEvent.interrupted] ends a take, because only it means
  /// another app took the audio path away from us:
  ///
  /// - [AudioSessionEvent.ducked] is a request to be quieter, which a
  ///   recording cannot meaningfully honour and is not harmed by.
  /// - [AudioSessionEvent.becameNoisy] is an *output* route change —
  ///   headphones pulled out. It threatens playback, not capture, and
  ///   discarding a voice note because the user unplugged their earbuds is a
  ///   defect, not a safeguard. `just_audio` already pauses playback on this
  ///   signal itself.
  /// - [AudioSessionEvent.resumed] arrives after the take is already over.
  ///   Silently reopening the microphone once a call ends is not something the
  ///   user asked for.
  static AiRecordingAbort? abortFor(AudioSessionEvent event) =>
      event == AudioSessionEvent.interrupted
      ? AiRecordingAbort.interrupted
      : null;

  void _onSessionEvent(AudioSessionEvent event) {
    // Only a live take cares.
    if (_startedAt == null) return;
    final abort = abortFor(event);
    if (abort != null) _abort(abort);
  }

  void _abort(AiRecordingAbort reason) {
    if (_disposed || _aborts.isClosed) return;
    _aborts.add(reason);
  }
}
