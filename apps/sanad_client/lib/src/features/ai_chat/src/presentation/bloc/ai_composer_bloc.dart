import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_chat_attachment.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/enums/ai_attachment_status.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/enums/ai_recording_status.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/enums/ai_speech_status.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_attachment_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_audio_player.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_audio_recorder.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_permission_gateway.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_speech_recognizer.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/usecases/audio_level_scale.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/usecases/speech_locale_resolver.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/usecases/validate_attachment.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/usecases/voice_note_transcript.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/audio_playback_controller.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/recording_level_controller.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/speech_transcript_controller.dart';

part 'ai_composer_event.dart';
part 'ai_composer_state.dart';

/// Owns what the user is *about to* send.
///
/// ## Why this is not part of `AiChatBloc`
///
/// Two reasons, both load-bearing:
///
/// 1. **Lifetime.** Composer state dies the moment a turn is sent; the
///    conversation outlives every turn. Merging them would mean the message
///    list carries draft state it has no business knowing about.
/// 2. **Rebuild cost.** Picking, validating and recording churn several times
///    per second. Routing that through `AiChatState.messages` would emit a new
///    message list on every tick and rebuild the whole conversation — exactly
///    what `ActiveStreamController` exists to prevent.
///
/// It is deliberately *one* composer bloc and not one per modality. Images,
/// documents and audio are the same responsibility — staging a turn — and
/// splitting them would triple the wiring for no separation gain.
///
/// ## What it never does
///
/// No plugin call, no `BuildContext`, no `dart:io`, no `Timer`. Acquisition
/// lives behind [AiAttachmentSource], capture behind [AiAudioRecorder],
/// playback behind [AiAudioPlayer], permissions behind [AiPermissionGateway] —
/// so every path here is exercisable with four fakes and no device.
class AiComposerBloc extends Bloc<AiComposerEvent, AiComposerState> {
  /// Creates the composer.
  ///
  /// The two controllers are injectable so a test can watch the hot path
  /// without reaching into the bloc.
  AiComposerBloc({
    required AiAttachmentSource attachmentSource,
    required AiAudioRecorder recorder,
    required AiAudioPlayer player,
    required AiPermissionGateway permissions,
    required AiSpeechRecognizer recognizer,

    /// Reads the app's current language code, for choosing a recognition
    /// locale. Injected as a getter rather than a value because the user can
    /// change language while the chat is open, and injected rather than read
    /// from the service locator because a bloc that calls `sl<>` cannot be
    /// tested without one. `app_di.dart` already passes
    /// `() => sl<TranslateBloc>().state.languageCode` this way.
    required String Function() resolveLanguageCode,
    this.rules = const AiAttachmentRules(),
    ValidateAttachment? validate,
    RecordingLevelController? recordingLevel,
    AudioPlaybackController? playback,
    SpeechTranscriptController? transcript,
  }) : _source = attachmentSource,
       _recorder = recorder,
       _player = player,
       _permissions = permissions,
       _recognizer = recognizer,
       _resolveLanguageCode = resolveLanguageCode,
       _validate = validate ?? ValidateAttachment(rules: rules),
       recordingLevel = recordingLevel ?? RecordingLevelController(),
       playback = playback ?? AudioPlaybackController(),
       transcript = transcript ?? SpeechTranscriptController(),
       super(const AiComposerState()) {
    // A second tap while the picker is open is meaningless — the OS already
    // has the foreground — so those are dropped rather than queued.
    on<AiComposerAttachmentRequested>(
      _onAttachmentRequested,
      transformer: droppable(),
    );
    on<AiComposerAttachmentRemoved>(_onAttachmentRemoved);
    on<AiComposerSubmitted>(_onSubmitted);
    on<AiComposerNoticeDismissed>(_onNoticeDismissed);
    on<AiComposerSettingsRequested>(_onSettingsRequested);
    // `sequential` keeps two events *of the same type* from interleaving — a
    // second stop cannot overtake the first. It does **not** order events
    // across types: `Bloc.on<E>` filters the stream by `E` before applying the
    // transformer, so each registration below is its own pipeline and a stop
    // runs concurrently with a start. Ordering *between* recording transitions
    // is what `_startInFlight` / `_pendingRelease` / `_releaseInFlight` are
    // for; do not delete them believing this transformer covers it.
    on<AiComposerRecordingStarted>(
      _onRecordingStarted,
      transformer: sequential(),
    );
    on<AiComposerRecordingLocked>(
      _onRecordingLocked,
      transformer: sequential(),
    );
    on<AiComposerRecordingHintRequested>(_onRecordingHintRequested);
    on<AiComposerRecordingStopped>(
      _onRecordingStopped,
      transformer: sequential(),
    );
    on<AiComposerRecordingCancelled>(
      _onRecordingCancelled,
      transformer: sequential(),
    );
    on<AiComposerRecordingAborted>(
      _onRecordingAborted,
      transformer: sequential(),
    );
    on<AiComposerPlaybackToggled>(
      _onPlaybackToggled,
      transformer: sequential(),
    );
    // Dictation transitions get the same treatment as recording, and for the
    // same reason: a stop that overtook its start would strand the recogniser.
    on<AiComposerPlaybackStopped>(
      _onPlaybackStopped,
      transformer: sequential(),
    );
    on<AiComposerSpeechStarted>(_onSpeechStarted, transformer: sequential());
    on<AiComposerSpeechStopped>(_onSpeechStopped, transformer: sequential());
    on<AiComposerSpeechCancelled>(
      _onSpeechCancelled,
      transformer: sequential(),
    );
    on<AiComposerSpeechEnded>(_onSpeechEnded, transformer: sequential());
    on<AiComposerSpeechFailed>(_onSpeechFailed, transformer: sequential());
    on<AiComposerBackgrounded>(_onBackgrounded, transformer: sequential());

    // `this.` because the constructor parameters of the same name are still in
    // scope here and are nullable.
    _sampleSubscription = _recorder.samples.listen((sample) {
      // The envelope is the take's real shape, accumulated as it happens.
      // There is no other moment to capture it: once `stop()` returns, all we
      // have is a file.
      _envelope.add(sample.level);
      this.recordingLevel.add(sample);

      // The take's own tick is the clock. Reaching the cap ends the take here
      // rather than in a `Timer`, which is how the feature manages to contain
      // none at all. `isCapturing` makes it fire once: the first stop moves
      // the state to `encoding` and later ticks fall through.
      if (sample.elapsed >= rules.maxRecordingDuration &&
          state.recording.isCapturing) {
        add(const AiComposerRecordingStopped());
      }
    });
    _abortSubscription = _recorder.aborts.listen(
      (reason) => add(AiComposerRecordingAborted(reason)),
    );
    _progressSubscription = _player.progress.listen(_onPlaybackProgress);

    // Partial results go straight to the controller and emit no state at all —
    // the whole reason dictation does not rebuild the conversation.
    //
    // The `_transcribingTake` branch in each of these three is what lets one
    // recogniser serve two callers. During a voice note it is feeding the
    // take's accumulator, and must not write the composer's text field, raise a
    // dictation banner, or move the dictation state machine.
    _transcriptSubscription = _recognizer.transcripts.listen((value) {
      if (_transcribingTake) {
        takeTranscript.accept(value);
        return;
      }
      this.transcript.value = value;
    });
    _speechFailureSubscription = _recognizer.failures.listen((failure) {
      // A recogniser that cannot run during a take is not the user's problem:
      // they asked for a voice note and they are getting one. The transcript
      // is simply absent.
      if (_transcribingTake) {
        _transcribingTake = false;
        return;
      }
      add(AiComposerSpeechFailed(failure));
    });
    // The platform decides when a phrase is over, so a recogniser that stops
    // itself has to be able to move the state machine.
    _speechListeningSubscription = _recognizer.listening.listen((listening) {
      if (listening) return;
      // Mid-take the recogniser ending is routine — it is built for phrases
      // and settles after `pauseFor`. Settle what it heard and start it again,
      // so a pause to think does not truncate the take's transcript.
      if (_transcribingTake) {
        takeTranscript.commit();
        if (state.recording.isCapturing) unawaited(_resumeTakeTranscription());
        return;
      }
      if (state.speech == AiSpeechStatus.listening) {
        add(const AiComposerSpeechEnded());
      }
    });
  }

  /// What an attachment is allowed to be.
  final AiAttachmentRules rules;

  /// Live microphone reading. Read directly by the recording bar; never state.
  final RecordingLevelController recordingLevel;

  /// Playback position. Read directly by the audio row; never state.
  final AudioPlaybackController playback;

  /// Words being recognised right now. Read directly by the composer's text
  /// field and the dictation bar; never state.
  final SpeechTranscriptController transcript;

  final AiAttachmentSource _source;
  final AiAudioRecorder _recorder;
  final AiAudioPlayer _player;
  final AiPermissionGateway _permissions;
  final AiSpeechRecognizer _recognizer;
  final String Function() _resolveLanguageCode;
  final ValidateAttachment _validate;

  /// The shape of the take currently being recorded. Reset per take.
  final AudioLevelEnvelope _envelope = AudioLevelEnvelope();

  /// What the recogniser heard during the take currently being recorded.
  ///
  /// Visible for tests, like the three controllers above, and reset per take.
  /// It is deliberately not state: it changes several times a second and
  /// nothing on screen renders it — a voice note shows its waveform, not its
  /// words.
  final VoiceNoteTranscript takeTranscript = VoiceNoteTranscript();

  /// Whether the recogniser is currently running *for a recording* rather than
  /// for dictation.
  ///
  /// The two are the same plugin and the same three streams, so this is what
  /// tells them apart. It is a plain field and not part of [AiComposerState] on
  /// purpose: `state.speech` describes the dictation capability the user can
  /// see and start, and a voice note must leave every invariant built on it —
  /// the mutual-exclusion checks, `canSend`, which bar the composer shows —
  /// exactly as it found them.
  bool _transcribingTake = false;

  /// True from the moment [_onRecordingStarted] begins until it returns.
  ///
  /// Bringing a take up is several awaits long — a permission round-trip, an
  /// availability check, the recorder itself — and every other recording
  /// handler runs concurrently with it (see the transformer note in the
  /// constructor). Those handlers read this instead of `state`, because during
  /// the window `state.recording` is `requestingPermission`, which every guard
  /// built on `isCapturing` correctly refuses to act on — and refusing is
  /// exactly wrong here: it leaves the take to start with nobody holding it.
  bool _startInFlight = false;

  /// A release the user performed while the take was still being brought up.
  ///
  /// Replayed by [_onRecordingStarted]'s `finally` once the take really
  /// exists, so it runs through the real handler rather than a second copy of
  /// its teardown.
  _PendingRelease? _pendingRelease;

  /// A lock the user performed while the take was still being brought up, or
  /// asked for up front via `AiComposerRecordingStarted.autoLock`.
  bool _pendingLock = false;

  /// True while a stop or a cancel is running.
  ///
  /// At most one terminal transition per take. Without this, a cancel-drag
  /// followed by the finger lifting dispatches both — different event types,
  /// so they run concurrently — and the stop calls `_recorder.stop()` on a
  /// recorder the cancel already tore down, turning a deliberate cancellation
  /// into a "nothing was recorded" failure. Enforced here rather than in the
  /// gesture widget so it is an invariant of the bloc and testable without a
  /// `testWidgets`.
  bool _releaseInFlight = false;

  StreamSubscription<AiRecordingSample>? _sampleSubscription;
  StreamSubscription<AiRecordingAbort>? _abortSubscription;
  StreamSubscription<AiPlaybackProgress>? _progressSubscription;
  StreamSubscription<AiSpeechTranscript>? _transcriptSubscription;
  StreamSubscription<AiSpeechFailure>? _speechFailureSubscription;
  StreamSubscription<bool>? _speechListeningSubscription;

  bool _closed = false;

  // ── attachments ───────────────────────────────────────────────────────────

  Future<void> _onAttachmentRequested(
    AiComposerAttachmentRequested event,
    Emitter<AiComposerState> emit,
  ) async {
    if (state.attachments.length >= rules.maxAttachments) {
      emit(state.copyWith(notice: _notice(AiAttachmentFailureKeys.tooMany)));
      return;
    }

    emit(state.copyWith(isPicking: true));
    final result = await _source.pick(event.intent);
    if (_closed) return;

    switch (result) {
      case AiAttachmentPickCancelled():
        // Backing out is not a failure and says nothing to the user.
        emit(state.copyWith(isPicking: false));

      case AiAttachmentPickDenied(:final permanently):
        emit(
          state.copyWith(
            isPicking: false,
            notice: _notice(
              permanently
                  ? 'ai_chat.permission_denied_permanently'
                  : 'ai_chat.permission_denied',
              canOpenSettings: permanently,
            ),
          ),
        );

      case AiAttachmentPickFailed(:final failureKey):
        emit(state.copyWith(isPicking: false, notice: _notice(failureKey)));

      case AiAttachmentsPicked(:final attachments):
        emit(_accept(attachments).copyWith(isPicking: false));
    }
  }

  /// Validates a freshly picked batch against the rules and what is already
  /// staged.
  ///
  /// A rejected attachment is **not** staged as a failed tile. Retrying a file
  /// that is too large or of the wrong type cannot succeed, so a tile the user
  /// must then dismiss is worse than a single explanation. Attachments that
  /// fail *later*, during preparation, do keep their tile.
  AiComposerState _accept(List<AiChatAttachment> picked) {
    final accepted = [...state.attachments];
    String? firstFailure;

    for (final attachment in picked) {
      // Counted against the running total, so a batch cannot overshoot the
      // limit by arriving all at once.
      final validated = _validate(attachment, currentCount: accepted.length);
      if (validated.isReady) {
        accepted.add(validated);
      } else {
        firstFailure ??= validated.failureKey;
      }
    }

    return state.copyWith(
      attachments: accepted,
      notice: firstFailure == null ? null : _notice(firstFailure),
    );
  }

  Future<void> _onAttachmentRemoved(
    AiComposerAttachmentRemoved event,
    Emitter<AiComposerState> emit,
  ) async {
    final removed = state.attachments
        .where((a) => a.id == event.id)
        .firstOrNull;
    if (removed == null) return;

    if (playback.value.isLoaded(event.id)) {
      await _player.stop();
      playback.clear();
    }

    emit(
      state.copyWith(
        attachments: state.attachments.where((a) => a.id != event.id).toList(),
        // Only a *previewed* take returns the status to idle. Today no other
        // shape is reachable — `_onRecordingStarted` refuses while
        // `occupiesComposer`, so a staged voice note and a live recorder
        // cannot coexist — but the unqualified check said "any audio
        // attachment removed means recording is over", which is a claim about
        // the recorder that this handler is in no position to make. The moment
        // keeping one take and starting another is allowed, it would strand
        // the second recorder.
        recording:
            removed is AiAudioAttachment &&
                state.recording == AiRecordingStatus.preview
            ? AiRecordingStatus.idle
            : null,
      ),
    );

    await _discardIfOurs(removed);
  }

  Future<void> _onSubmitted(
    AiComposerSubmitted event,
    Emitter<AiComposerState> emit,
  ) async {
    // The files now belong to a message in the conversation, so they are
    // deliberately *not* deleted here.
    if (playback.value.attachmentId != null) {
      await _player.stop();
      playback.clear();
    }
    recordingLevel.reset();
    transcript.reset();
    takeTranscript.reset();
    _envelope.reset();
    emit(const AiComposerState());
  }

  void _onNoticeDismissed(
    AiComposerNoticeDismissed event,
    Emitter<AiComposerState> emit,
  ) => emit(state.copyWith(clearNotice: true));

  Future<void> _onSettingsRequested(
    AiComposerSettingsRequested event,
    Emitter<AiComposerState> emit,
  ) async {
    emit(state.copyWith(clearNotice: true));
    await _permissions.openSettings();
  }

  // ── recording ─────────────────────────────────────────────────────────────

  Future<void> _onRecordingStarted(
    AiComposerRecordingStarted event,
    Emitter<AiComposerState> emit,
  ) async {
    // The same one-capability rule dictation enforces, from the other side:
    // `occupiesComposer` covers a take already running, `speech.isActive`
    // covers the recogniser holding the microphone.
    if (state.recording.occupiesComposer || state.speech.isActive) return;
    if (state.attachments.length >= rules.maxAttachments) {
      emit(state.copyWith(notice: _notice(AiAttachmentFailureKeys.tooMany)));
      return;
    }

    _startInFlight = true;
    _pendingRelease = null;
    _pendingLock = event.autoLock;
    try {
      _envelope.reset();
      // The min-take guard reads this clock, so it must belong to *this* take
      // and not carry the previous one's last reading.
      recordingLevel.reset();
      emit(state.copyWith(recording: AiRecordingStatus.requestingPermission));

      final outcome = await _permissions.ensureMicrophone();
      if (_closed) return;

      if (!outcome.isGranted) {
        emit(
          state.copyWith(
            recording: AiRecordingStatus.permissionDenied,
            notice: _notice(
              outcome.needsSettings
                  ? 'ai_chat.microphone_denied_permanently'
                  : 'ai_chat.microphone_denied',
              canOpenSettings: outcome.needsSettings,
            ),
          ),
        );
        return;
      }

      // Released before the microphone was ever opened — the common shape of
      // the first-ever permission prompt, which steals the pointer and cancels
      // the gesture while this handler is parked above. Returning here skips an
      // audio-session activate/start/cancel round-trip for a take nobody
      // wanted, and says nothing: the user tapped Allow and can now press and
      // hold, which is what every messaging app does.
      if (_pendingRelease != null) {
        emit(state.copyWith(recording: AiRecordingStatus.idle));
        return;
      }

      if (!await _recorder.isAvailable) {
        if (_closed) return;
        emit(
          state.copyWith(
            recording: AiRecordingStatus.failed,
            notice: _notice('ai_chat.microphone_unavailable'),
          ),
        );
        return;
      }

      try {
        await _recorder.start(maxDuration: rules.maxRecordingDuration);
        if (_closed) return;
        // The single point where a take's interaction is decided, which is why
        // `autoLock` is a flag on this event rather than a second one.
        emit(
          state.copyWith(
            recording: _pendingLock
                ? AiRecordingStatus.lockedRecording
                : AiRecordingStatus.recording,
          ),
        );
        // After the recorder, never before: the audio file is the deliverable
        // and must not wait on a recogniser that may not be there. Every
        // failure inside is swallowed.
        await _startTakeTranscription();
      } on Object {
        if (_closed) return;
        emit(
          state.copyWith(
            recording: AiRecordingStatus.failed,
            notice: _notice('ai_chat.recording_failed'),
          ),
        );
      }
    } finally {
      // A `finally` and not an inline check after each await: the release can
      // land at any of the five await boundaries above, and this covers all of
      // them in one place.
      _startInFlight = false;
      final release = _pendingRelease;
      _pendingRelease = null;
      _pendingLock = false;

      // Replay it now the take really exists, through the real handler rather
      // than a second copy of its teardown. The elapsed clock is still near
      // zero, so a replayed stop lands in the min-take guard and is cleaned up
      // there.
      if (release != null && !_closed && state.recording.isCapturing) {
        add(
          release == _PendingRelease.cancel
              ? const AiComposerRecordingCancelled()
              : const AiComposerRecordingStopped(),
        );
      }
    }
  }

  /// The take goes hands-free.
  ///
  /// Nothing is asked of the recorder: the microphone is already live, the
  /// samples are already arriving, and the file is already being written. All
  /// that changes is which interaction ends the take — which is exactly why
  /// this is one `emit` and not a second recording path.
  ///
  /// Only a held take can lock. A lock arriving against `requestingPermission`,
  /// `encoding`, `preview` or a failure is a gesture the state machine has
  /// already moved past; the accessibility path, which wants a take that is
  /// locked from the outset, uses `AiComposerRecordingStarted(locked: true)`
  /// instead of racing this.
  Future<void> _onRecordingLocked(
    AiComposerRecordingLocked event,
    Emitter<AiComposerState> emit,
  ) async {
    // Locked before the take finished coming up: latch it, and the start
    // handler applies it at its single decision point. Reachable in practice —
    // the long-press deadline fires, then a fast upward flick can beat a
    // platform-channel permission round-trip on a cold device — and dropping it
    // would leave the user's finger coming up onto an unlocked take after they
    // saw the lock affordance engage.
    if (_startInFlight) {
      _pendingLock = true;
      return;
    }
    // Anything else — idle, permissionDenied, a take already failed by an
    // interruption, encoding, preview, or already locked — is a stale
    // affordance and says nothing.
    if (state.recording != AiRecordingStatus.recording) return;
    emit(state.copyWith(recording: AiRecordingStatus.lockedRecording));
  }

  /// The user tapped the microphone rather than holding it.
  ///
  /// Deliberately does not start anything. The hold threshold exists so a
  /// brush against the button cannot put a voice message into the
  /// conversation, and a tap that quietly started one would defeat it.
  void _onRecordingHintRequested(
    AiComposerRecordingHintRequested event,
    Emitter<AiComposerState> emit,
  ) => emit(
    state.copyWith(
      notice: _notice('ai_chat.record_hold_hint', tone: AiNoticeTone.info),
    ),
  );

  Future<void> _onRecordingStopped(
    AiComposerRecordingStopped event,
    Emitter<AiComposerState> emit,
  ) async {
    // The take is still being brought up; the start handler owns the outcome.
    // `??=` and not `=`: a cancel already latched must not be downgraded.
    if (_startInFlight) {
      _pendingRelease ??= _PendingRelease.stop;
      return;
    }
    if (_releaseInFlight) return;
    if (!state.recording.isCapturing) return;
    _releaseInFlight = true;
    try {
      await _stopTake(emit);
    } finally {
      _releaseInFlight = false;
    }
  }

  Future<void> _stopTake(Emitter<AiComposerState> emit) async {
    // Too short to have been meant. Take the cancel path rather than the
    // encode one: there is no take worth keeping, and `stop()` on a take this
    // brief returns either nothing or an unplayable blip.
    //
    // This is also where the release-before-start race lands. `sequential()`
    // holds a stop dispatched during `requestingPermission` until the start
    // handler finishes, so it arrives here against an elapsed of zero.
    if (recordingLevel.value.elapsed < rules.minRecordingDuration) {
      await _recorder.cancel();
      await _discardTakeTranscription();
      recordingLevel.reset();
      _envelope.reset();
      if (_closed) return;
      emit(
        state.copyWith(
          recording: AiRecordingStatus.idle,
          notice: _notice(
            'ai_chat.recording_too_short',
            tone: AiNoticeTone.info,
          ),
        ),
      );
      return;
    }

    emit(state.copyWith(recording: AiRecordingStatus.encoding));
    final elapsed = recordingLevel.value.elapsed;
    final waveform = _waveformSoFar();
    // Before `_recorder.stop()`: asking the recogniser for its final result is
    // the slow half, and it can settle while the encoder finishes.
    final transcribed = await _stopTakeTranscription();

    final String? path;
    try {
      path = await _recorder.stop();
    } on Object {
      if (_closed) return;
      recordingLevel.reset();
      takeTranscript.reset();
      emit(
        state.copyWith(
          recording: AiRecordingStatus.failed,
          notice: _notice('ai_chat.recording_failed'),
        ),
      );
      return;
    }
    if (_closed) return;

    recordingLevel.reset();

    if (path == null) {
      takeTranscript.reset();
      emit(
        state.copyWith(
          recording: AiRecordingStatus.failed,
          notice: _notice('ai_chat.recording_empty'),
        ),
      );
      return;
    }

    final attachment = AiAudioAttachment(
      id: 'att_${generateUuidV4()}',
      fileName: path.split(RegExp(r'[/\\]')).last,
      // The recorder is the only thing that knows the real size; the composer
      // does not stat files. Validation of a recording is by duration, which
      // `maxRecordingDuration` already bounded.
      sizeBytes: 1,
      mimeType: 'audio/mp4',
      localPath: path,
      duration: elapsed,
      status: AiAttachmentStatus.ready,
      waveform: waveform,
      // Empty whenever the recogniser was unavailable, lost the microphone to
      // the recorder, or heard nothing. That is a bonus withheld, not a
      // failure, so it raises nothing.
      transcript: transcribed,
    );

    emit(
      state.copyWith(
        recording: AiRecordingStatus.preview,
        attachments: [...state.attachments, attachment],
      ),
    );
  }

  Future<void> _onRecordingCancelled(
    AiComposerRecordingCancelled event,
    Emitter<AiComposerState> emit,
  ) async {
    // `=` and not `??=`: a cancel supersedes a latched stop. Discarding what
    // the user asked to discard is always the safe direction.
    if (_startInFlight) {
      _pendingRelease = _PendingRelease.cancel;
      return;
    }
    if (_releaseInFlight) return;
    if (!state.recording.occupiesComposer) return;
    _releaseInFlight = true;
    try {
      await _cancelTake(emit);
    } finally {
      _releaseInFlight = false;
    }
  }

  Future<void> _cancelTake(Emitter<AiComposerState> emit) async {
    await _recorder.cancel();
    await _discardTakeTranscription();
    recordingLevel.reset();
    _envelope.reset();
    if (_closed) return;

    // Cancelling from preview also throws away the finished take.
    final take = state.attachments.whereType<AiAudioAttachment>().lastOrNull;
    if (state.recording == AiRecordingStatus.preview && take != null) {
      emit(
        state.copyWith(
          recording: AiRecordingStatus.idle,
          attachments: state.attachments.where((a) => a.id != take.id).toList(),
        ),
      );
      await _discardIfOurs(take);
      return;
    }

    emit(state.copyWith(recording: AiRecordingStatus.idle));
  }

  Future<void> _onRecordingAborted(
    AiComposerRecordingAborted event,
    Emitter<AiComposerState> emit,
  ) async {
    // An interruption while the take is still coming up must not be dropped, or
    // the recorder opens into an audio session the OS has already given away.
    // Latched as a cancellation: the notice is lost, but a silently-discarded
    // take beats one recording into a phone call.
    if (_startInFlight) {
      _pendingRelease = _PendingRelease.cancel;
      return;
    }
    if (_releaseInFlight) return;
    if (!state.recording.occupiesComposer) return;
    _releaseInFlight = true;
    try {
      await _abortTake(event, emit);
    } finally {
      _releaseInFlight = false;
    }
  }

  Future<void> _abortTake(
    AiComposerRecordingAborted event,
    Emitter<AiComposerState> emit,
  ) async {
    await _recorder.cancel();
    await _discardTakeTranscription();
    recordingLevel.reset();
    _envelope.reset();
    if (_closed) return;

    emit(
      state.copyWith(
        recording: event.reason == AiRecordingAbort.cancelled
            ? AiRecordingStatus.idle
            : AiRecordingStatus.failed,
        notice: switch (event.reason) {
          AiRecordingAbort.cancelled => null,
          AiRecordingAbort.interrupted => _notice(
            'ai_chat.recording_interrupted',
          ),
          AiRecordingAbort.failed => _notice('ai_chat.recording_failed'),
        },
      ),
    );
  }

  // ── the take's transcript ─────────────────────────────────────────────────

  /// Brings the recogniser up alongside a running take. Best-effort.
  ///
  /// Every failure here — no recogniser on the device, no permission for it, a
  /// microphone the recorder will not share — is swallowed. The user asked for
  /// a voice note, not for dictation, and they are getting one either way; a
  /// banner would blame them for a capability they never invoked.
  ///
  /// Notably absent: any permission prompt. Recording already established
  /// microphone access, and iOS's separate speech-recognition grant is asked
  /// for by the dictation button, which is a thing the user chose. Prompting
  /// mid-recording would interrupt the take to ask about a bonus.
  Future<void> _startTakeTranscription() async {
    takeTranscript.reset();
    try {
      if (!await _recognizer.initialize()) return;
      if (_closed) return;

      final localeId = SpeechLocaleResolver.resolve(
        languageCode: _resolveLanguageCode(),
        available: await _recognizer.availableLocales(),
      );
      if (_closed) return;

      // The take can end while this is still bringing the recogniser up — a
      // stop on a locked take, an interruption — and setting the flag then
      // would route the *next* dictation's words into the take accumulator,
      // leaving the composer's text field permanently empty.
      if (!state.recording.isCapturing) return;

      // Set before `start`, so the very first result the plugin delivers is
      // already routed to the accumulator rather than the text field.
      _transcribingTake = true;
      await _recognizer.start(localeId: localeId);
    } on Object {
      _transcribingTake = false;
    }
  }

  /// Restarts the recogniser for a take that is still running.
  ///
  /// See the `listening` subscription: the recogniser settles after its own
  /// pause, and a five-minute recording outlives many of its sessions.
  Future<void> _resumeTakeTranscription() async {
    if (_closed || !_transcribingTake) return;
    try {
      await _recognizer.start(
        localeId: SpeechLocaleResolver.resolve(
          languageCode: _resolveLanguageCode(),
          available: await _recognizer.availableLocales(),
        ),
      );
    } on Object {
      // The take keeps whatever it heard up to here.
      _transcribingTake = false;
    }
  }

  /// Ends the take's recognition and returns what was heard.
  Future<String> _stopTakeTranscription() async {
    if (!_transcribingTake) return '';
    _transcribingTake = false;
    try {
      await _recognizer.stop();
    } on Object {
      // Whatever already arrived still counts.
    }
    takeTranscript.commit();
    return takeTranscript.text;
  }

  /// Ends the take's recognition and throws away what was heard.
  Future<void> _discardTakeTranscription() async {
    if (!_transcribingTake) {
      takeTranscript.reset();
      return;
    }
    _transcribingTake = false;
    try {
      await _recognizer.cancel();
    } on Object {
      // Cancelling something already stopped is not an error.
    }
    takeTranscript.reset();
  }

  /// The take's real peak envelope, as the fixed number of bars a finished
  /// recording keeps.
  ///
  /// This used to smear the single most recent level across forty bars with a
  /// fixed pattern, which meant every recording drew the same shape and a
  /// quiet one drew a flat line — a picture of nothing. [AudioLevelEnvelope]
  /// keeps the actual readings instead, bounded by folding itself in half, so
  /// a five-minute take costs no more to remember than a five-second one.
  List<double> _waveformSoFar() =>
      _envelope.resample(AiAudioAttachment.maxWaveformSamples);

  Future<void> _onPlaybackStopped(
    AiComposerPlaybackStopped event,
    Emitter<AiComposerState> emit,
  ) async {
    if (playback.value.attachmentId == null) return;
    await _player.stop();
    playback.clear();
  }

  // ── dictation ─────────────────────────────────────────────────────────────

  Future<void> _onSpeechStarted(
    AiComposerSpeechStarted event,
    Emitter<AiComposerState> emit,
  ) async {
    // One capability holds the microphone at a time. Refusing here is what
    // keeps dictation and recording from fighting over it, and it is a
    // decision rather than a race because both live in this bloc.
    if (state.isCapturing) return;

    // A voice note playing into the microphone would be transcribed. Stopping
    // playback also hands the audio session back, so the recogniser starts
    // against a quiet device.
    if (playback.value.attachmentId != null) {
      await _player.stop();
      playback.clear();
    }

    emit(state.copyWith(speech: AiSpeechStatus.requestingPermission));

    final microphone = await _permissions.ensureMicrophone();
    if (_closed) return;
    if (!microphone.isGranted) {
      emit(_speechDenied(microphone));
      return;
    }

    // iOS treats recognition as its own grant with its own prompt; on Android
    // this is the same RECORD_AUDIO already allowed above and returns at once.
    final recognition = await _permissions.ensureSpeechRecognition();
    if (_closed) return;
    if (!recognition.isGranted) {
      emit(_speechDenied(recognition));
      return;
    }

    emit(state.copyWith(speech: AiSpeechStatus.starting));
    transcript.reset();

    if (!await _recognizer.initialize()) {
      if (_closed) return;
      emit(
        state.copyWith(
          speech: AiSpeechStatus.error,
          notice: _notice('ai_chat.speech_unavailable'),
        ),
      );
      return;
    }
    if (_closed) return;

    // Ask the device what it can actually recognise rather than asserting a
    // tag. `null` back means no recogniser for this language — the device's
    // own default is a better answer than refusing to dictate at all.
    final localeId = SpeechLocaleResolver.resolve(
      languageCode: _resolveLanguageCode(),
      available: await _recognizer.availableLocales(),
    );
    if (_closed) return;

    try {
      await _recognizer.start(localeId: localeId);
      if (_closed) return;
      emit(state.copyWith(speech: AiSpeechStatus.listening));
    } on Object {
      if (_closed) return;
      emit(
        state.copyWith(
          speech: AiSpeechStatus.error,
          notice: _notice('ai_chat.speech_failed'),
        ),
      );
    }
  }

  AiComposerState _speechDenied(AiPermissionOutcome outcome) => state.copyWith(
    speech: AiSpeechStatus.error,
    notice: _notice(
      outcome.needsSettings
          ? 'ai_chat.speech_denied_permanently'
          : 'ai_chat.speech_denied',
      canOpenSettings: outcome.needsSettings,
    ),
  );

  Future<void> _onSpeechStopped(
    AiComposerSpeechStopped event,
    Emitter<AiComposerState> emit,
  ) async {
    if (!state.speech.isActive) return;

    emit(state.copyWith(speech: AiSpeechStatus.finalizing));
    await _recognizer.stop();
    if (_closed) return;

    // The text is already in the composer, put there by the transcript
    // controller as it arrived. Nothing to move here — from now on it is
    // ordinary editable text.
    emit(state.copyWith(speech: AiSpeechStatus.completed));
  }

  Future<void> _onSpeechCancelled(
    AiComposerSpeechCancelled event,
    Emitter<AiComposerState> emit,
  ) async {
    if (!state.speech.isActive) return;

    await _recognizer.cancel();
    transcript.reset();
    if (_closed) return;

    emit(state.copyWith(speech: AiSpeechStatus.idle));
  }

  Future<void> _onSpeechEnded(
    AiComposerSpeechEnded event,
    Emitter<AiComposerState> emit,
  ) async {
    if (!state.speech.isActive) return;
    // The recogniser let go by itself. Whatever it heard stands.
    emit(state.copyWith(speech: AiSpeechStatus.completed));
  }

  Future<void> _onSpeechFailed(
    AiComposerSpeechFailed event,
    Emitter<AiComposerState> emit,
  ) async {
    // A failure that arrives after the user already cancelled — the plugin
    // reports one on its way down — must not raise a banner about a dictation
    // nobody is waiting on any more.
    if (state.speech == AiSpeechStatus.idle) return;

    await _recognizer.cancel();
    if (_closed) return;

    // Hearing nothing is not a failure worth a red banner — it is the normal
    // outcome of pressing the button and then not speaking. The composer just
    // goes quiet again.
    if (event.failure == AiSpeechFailure.noMatch ||
        event.failure == AiSpeechFailure.timeout) {
      transcript.reset();
      emit(state.copyWith(speech: AiSpeechStatus.idle));
      return;
    }

    emit(
      state.copyWith(
        speech: AiSpeechStatus.error,
        notice: _notice(
          switch (event.failure) {
            AiSpeechFailure.permissionDenied => 'ai_chat.speech_denied',
            AiSpeechFailure.permissionPermanentlyDenied =>
              'ai_chat.speech_denied_permanently',
            AiSpeechFailure.unavailable => 'ai_chat.speech_unavailable',
            AiSpeechFailure.network => 'ai_chat.speech_network',
            _ => 'ai_chat.speech_failed',
          },
          canOpenSettings:
              event.failure == AiSpeechFailure.permissionPermanentlyDenied,
        ),
      ),
    );
  }

  // ── app lifecycle ─────────────────────────────────────────────────────────

  /// The app left the foreground.
  ///
  /// Separate from an audio-session interruption, and handled separately. An
  /// interruption means another app took the audio path and arrives on
  /// `AudioSessionManager.events`; this means the OS put us behind something
  /// else, which no audio signal reports. Android also stops delivering
  /// microphone data to a backgrounded app without a foreground service, so a
  /// take that survives here is silently dead anyway.
  ///
  /// Every capability this bloc owns is released, and a partial recording is
  /// deleted rather than left on disk for a future user to run out of space
  /// over.
  Future<void> _onBackgrounded(
    AiComposerBackgrounded event,
    Emitter<AiComposerState> emit,
  ) async {
    if (state.speech.isActive) {
      await _recognizer.cancel();
      transcript.reset();
      if (_closed) return;
      emit(state.copyWith(speech: AiSpeechStatus.idle));
    }

    // A take still coming up has no recorder to stop yet, so latch it and let
    // the start handler tear it down. Deliberately not an early return: speech
    // and playback below still need releasing.
    if (_startInFlight) _pendingRelease = _PendingRelease.cancel;

    if (!_startInFlight && state.recording.isCapturing) {
      // `cancel` stops the recorder, releases the audio session and deletes
      // the partial file — the same path the user's own cancel takes.
      await _recorder.cancel();
      await _discardTakeTranscription();
      recordingLevel.reset();
      _envelope.reset();
      if (_closed) return;
      emit(state.copyWith(recording: AiRecordingStatus.idle));
    }

    if (playback.value.attachmentId != null) {
      await _player.stop();
      playback.clear();
    }
  }

  // ── playback ──────────────────────────────────────────────────────────────

  Future<void> _onPlaybackToggled(
    AiComposerPlaybackToggled event,
    Emitter<AiComposerState> emit,
  ) async {
    final attachment = event.attachment;

    if (playback.value.isPlaying(attachment.id)) {
      await _player.pause();
      return;
    }

    if (playback.value.isLoaded(attachment.id)) {
      await _player.resume();
      return;
    }

    playback.load(attachment.id);
    try {
      await _player.play(id: attachment.id, path: attachment.localPath);
    } on Object {
      if (_closed) return;
      playback.clear();
      emit(state.copyWith(notice: _notice('ai_chat.playback_failed')));
    }
  }

  void _onPlaybackProgress(AiPlaybackProgress progress) {
    // Ignore ticks for a clip that is no longer the loaded one, so a late
    // frame from a stopped player cannot move the wrong row's scrubber.
    if (playback.value.attachmentId == null) return;
    if (_player.currentId != playback.value.attachmentId) return;
    playback.update(progress);
  }

  // ── plumbing ──────────────────────────────────────────────────────────────

  AiComposerNotice _notice(
    String messageKey, {
    bool canOpenSettings = false,
    AiNoticeTone tone = AiNoticeTone.error,
  }) => AiComposerNotice(
    // A fresh id per occurrence, so two identical failures in a row still
    // read as a change and the second one is not swallowed.
    id: generateUuidV4(),
    messageKey: messageKey,
    canOpenSettings: canOpenSettings,
    tone: tone,
  );

  /// Deletes the backing file when we were the ones who created it.
  ///
  /// Picker files live in the picker's own cache and are not ours to remove;
  /// recordings are.
  Future<void> _discardIfOurs(AiChatAttachment attachment) async {
    if (attachment is! AiAudioAttachment) return;
    await _recorder.discard(attachment.localPath);
  }

  @override
  Future<void> close() async {
    if (_closed) return super.close();
    _closed = true;

    await _sampleSubscription?.cancel();
    await _abortSubscription?.cancel();
    await _progressSubscription?.cancel();
    await _transcriptSubscription?.cancel();
    await _speechFailureSubscription?.cancel();
    await _speechListeningSubscription?.cancel();
    _sampleSubscription = null;
    _abortSubscription = null;
    _progressSubscription = null;
    _transcriptSubscription = null;
    _speechFailureSubscription = null;
    _speechListeningSubscription = null;

    // Anything still staged never became a message, so its file is ours to
    // clean up. Recordings only — see `_discardIfOurs`.
    for (final attachment in state.attachments) {
      await _discardIfOurs(attachment);
    }

    _transcribingTake = false;
    _startInFlight = false;
    _releaseInFlight = false;
    _pendingRelease = null;
    _pendingLock = false;
    takeTranscript.reset();

    await _recorder.dispose();
    await _player.dispose();
    await _recognizer.dispose();

    recordingLevel.dispose();
    playback.dispose();
    transcript.dispose();

    return super.close();
  }
}

/// What the user did while a take was still being brought up.
enum _PendingRelease {
  /// Keep whatever was captured.
  stop,

  /// Throw it away.
  cancel,
}
