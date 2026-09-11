import 'dart:async';

import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_voice_event.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/enums/ai_voice_session_status.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_permission_gateway.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_voice_session.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/level_history.dart';

part 'ai_voice_session_event.dart';
part 'ai_voice_session_state.dart';

/// Carries the live microphone level for the voice screen.
///
/// The same family as `ActiveStreamController` and
/// `SpeechTranscriptController`, for the same reason: a level that ticks with
/// every audio frame must not become bloc state, or the whole voice screen
/// rebuilds dozens of times a second. Only the waveform listens here.
class VoiceLevelController extends ValueNotifier<double> {
  /// Starts silent.
  VoiceLevelController({int historyLength = LevelHistory.defaultLength})
    : _history = LevelHistory(length: historyLength),
      super(0);

  final LevelHistory _history;

  /// Recent levels, oldest first. The meter draws the series, not the single
  /// number — one value cannot show a voice rising and falling.
  List<double> get history => _history.values;

  /// Records one reading, updating [history] before notifying.
  void add(double level) {
    _history.add(level);
    value = level;
  }

  /// Returns to silence.
  void reset() {
    _history.clear();
    value = 0;
  }
}

/// Owns the live-voice session.
///
/// A separate bloc from `AiComposerBloc` because live voice is a separate
/// subsystem: it produces no message and no attachment, it holds the
/// microphone for its whole life rather than for one take, and it lives on its
/// own screen. Sharing state between the two would mean every consumer asking
/// which mode it is in.
///
/// The bloc owns *lifecycle* — permission, start, mute, interrupt, end — and
/// nothing else. The session's own state machine lives behind
/// [AiVoiceSession], so a real realtime transport replaces it without this
/// bloc or the screen changing.
class AiVoiceSessionBloc
    extends Bloc<AiVoiceSessionEvent, AiVoiceSessionState> {
  /// Creates the bloc.
  AiVoiceSessionBloc({
    required AiVoiceSession session,
    required AiPermissionGateway permissions,
    VoiceLevelController? level,
    AiUiValidator? validator,
    AiUiDiagnosticsSink diagnostics = const NoopAiUiDiagnosticsSink(),
    AiUiInteractionLedger? ledger,
  }) : _session = session,
       _permissions = permissions,
       _validator = validator ?? const AiUiValidator(),
       _diagnostics = diagnostics,
       level = level ?? VoiceLevelController(),
       ledger = ledger ?? AiUiInteractionLedger(),
       super(const AiVoiceSessionState()) {
    // Lifecycle transitions must never interleave: an `end` overtaking a
    // `start` would leave the microphone held with nothing listening.
    on<AiVoiceSessionStartRequested>(_onStart, transformer: sequential());
    on<AiVoiceSessionMuteToggled>(_onMuteToggled, transformer: sequential());
    on<AiVoiceSessionTurnFinished>(
      _onTurnFinished,
      transformer: sequential(),
    );
    on<AiVoiceSessionInterrupted>(_onInterrupted, transformer: sequential());
    on<AiVoiceSessionEndRequested>(_onEnd, transformer: sequential());
    on<AiVoiceSessionCloseRequested>(_onClose, transformer: sequential());
    on<AiVoiceSessionBackgrounded>(
      _onBackgrounded,
      transformer: sequential(),
    );
    on<AiVoiceSessionStatusChanged>(_onStatusChanged);
    on<AiVoiceSessionEventReceived>(_onSessionEvent);
    // Sequential with the rest of the lifecycle: an answer racing an `end`
    // would try to resume a session that is already tearing down.
    on<AiVoiceSessionInteractionSubmitted>(
      _onInteraction,
      transformer: sequential(),
    );
    on<AiVoiceSessionSettingsRequested>(_onSettingsRequested);

    _statusSubscription = _session.status.listen(
      (status) => add(AiVoiceSessionStatusChanged(status)),
    );
    _levelSubscription = _session.inputLevel.listen(
      (value) => this.level.add(value),
    );
    _eventSubscription = _session.events.listen(
      (event) => add(AiVoiceSessionEventReceived(event)),
    );
  }

  /// Live microphone level. Read directly by the waveform; never state.
  final VoiceLevelController level;

  /// The answer lifecycle of the card on screen.
  ///
  /// The same type the conversation uses, for the same reasons — see
  /// `AiChatBloc.ledger`. A voice session shows one card at a time, but the
  /// ledger still earns its place: it is what refuses a second tap while the
  /// first answer is in flight.
  final AiUiInteractionLedger ledger;

  final AiVoiceSession _session;
  final AiPermissionGateway _permissions;

  final AiUiValidator _validator;
  final AiUiDiagnosticsSink _diagnostics;

  StreamSubscription<AiVoiceSessionStatus>? _statusSubscription;
  StreamSubscription<double>? _levelSubscription;
  StreamSubscription<AiVoiceEvent>? _eventSubscription;

  bool _closed = false;

  Future<void> _onStart(
    AiVoiceSessionStartRequested event,
    Emitter<AiVoiceSessionState> emit,
  ) async {
    if (state.status.isActive) return;

    emit(
      state.copyWith(
        status: AiVoiceSessionStatus.connecting,
        clearFailure: true,
      ),
    );

    final outcome = await _permissions.ensureMicrophone();
    if (_closed) return;

    if (!outcome.isGranted) {
      emit(
        state.copyWith(
          status: AiVoiceSessionStatus.error,
          failureKey: outcome.needsSettings
              ? 'ai_chat.microphone_denied_permanently'
              : 'ai_chat.microphone_denied',
          canOpenSettings: outcome.needsSettings,
        ),
      );
      return;
    }

    await _session.start();
  }

  Future<void> _onMuteToggled(
    AiVoiceSessionMuteToggled event,
    Emitter<AiVoiceSessionState> emit,
  ) async {
    final muted = !state.isMuted;
    emit(state.copyWith(isMuted: muted));
    await _session.setMuted(muted: muted);
    if (muted) level.reset();
  }

  /// Hands the turn over to the assistant.
  ///
  /// Emits nothing: the session answers on its own `status` stream, which
  /// `AiVoiceSessionStatusChanged` already folds into state. Emitting
  /// `processing` here as well would make the UI briefly trust the button
  /// instead of the session, and the two could then disagree.
  Future<void> _onTurnFinished(
    AiVoiceSessionTurnFinished event,
    Emitter<AiVoiceSessionState> emit,
  ) => _session.finishTurn();

  Future<void> _onInterrupted(
    AiVoiceSessionInterrupted event,
    Emitter<AiVoiceSessionState> emit,
  ) => _session.interrupt();

  Future<void> _onEnd(
    AiVoiceSessionEndRequested event,
    Emitter<AiVoiceSessionState> emit,
  ) async {
    await _session.end();
    level.reset();
  }

  /// The user is leaving the screen (A-05).
  ///
  /// Tears the session down through the same [_onEnd] path — one way down —
  /// then latches [AiVoiceSessionState.closeRequested] so the route owner
  /// pops. Navigation itself stays out of here: this bloc knows the session is
  /// finished and that the user asked to leave, and nothing about routes.
  ///
  /// Idempotent, so tapping the close control repeatedly (which the user will
  /// do, because the first tap used to do nothing) is safe: the second call
  /// finds the session already ended and re-emits the same latched state.
  Future<void> _onClose(
    AiVoiceSessionCloseRequested event,
    Emitter<AiVoiceSessionState> emit,
  ) async {
    // The latch, not the status, is what says "already closing". `end()`
    // drives the status stream asynchronously, so a second tap arriving
    // before that lands would still see `listening` and tear down twice.
    if (state.closeRequested) return;

    if (!state.status.isTerminal && state.status != AiVoiceSessionStatus.idle) {
      await _session.end();
      level.reset();
    }
    if (_closed) return;
    emit(state.copyWith(closeRequested: true));
  }

  /// The app left the foreground.
  ///
  /// The same destination as the user pressing end, reached for a different
  /// reason — so it routes through the same `end()`, which releases the
  /// capture, the player and the audio session and leaves the session in a
  /// consistent `ended` state. Doing anything cleverer here would mean two
  /// teardown paths that have to agree.
  Future<void> _onBackgrounded(
    AiVoiceSessionBackgrounded event,
    Emitter<AiVoiceSessionState> emit,
  ) async {
    if (state.status.isTerminal || state.status == AiVoiceSessionStatus.idle) {
      return;
    }
    await _session.end();
    level.reset();
  }

  /// Ingests one semantic event.
  ///
  /// Validation happens here — once, on arrival — exactly as `AiChatBloc`
  /// validates a `ui` frame. No widget ever sees raw JSON, so no `build()`
  /// pays for decoding or can be surprised by a malformed payload.
  void _onSessionEvent(
    AiVoiceSessionEventReceived event,
    Emitter<AiVoiceSessionState> emit,
  ) {
    switch (event.event) {
      case AiVoiceUiRequested(:final payload):
        final result = _validator.validate(payload);
        _diagnostics.reportAll(result.diagnostics);
        // A payload that validated to nothing leaves the session speaking
        // rather than staring at an empty panel. The assistant's audio still
        // arrives; only the card is missing.
        if (!result.hasRenderableUi) return;
        // A new question replaces the previous answer's line.
        emit(
          state.copyWith(document: result.document, clearLastAnswer: true),
        );

      case AiVoiceUiResolved(:final nodeId):
        // The card comes down. A node still pending when the session dropped
        // it is returned to answerable rather than left disabled — nothing is
        // going to resolve a claim whose session has gone.
        if (nodeId != null) ledger.reset(nodeId);
        emit(state.copyWith(clearDocument: true));
    }
  }

  /// Hands one answer to the session and lets it resume.
  ///
  /// The ledger already accepted the submission — the sink claims it before
  /// this event is added — so this does not re-check for duplicates. What it
  /// does guard is the session itself: an answer arriving after teardown is
  /// dropped by the session, and the card is on its way off screen anyway.
  Future<void> _onInteraction(
    AiVoiceSessionInteractionSubmitted event,
    Emitter<AiVoiceSessionState> emit,
  ) async {
    await _session.submitInteraction(event.interaction);
    if (_closed) return;
    ledger.resolve(event.interaction.nodeId, event.interaction.status);

    // Keep what was answered on screen (A-08). The card is gone the moment it
    // is confirmed and the assistant's acknowledgement is audio only, so
    // without this the user has no record of what they just chose.
    //
    // A cancellation gets no line: nothing was chosen, and "you chose
    // nothing" is noise.
    emit(
      event.interaction.isSubmitted
          ? state.copyWith(lastAnswer: event.interaction.text)
          : state.copyWith(clearLastAnswer: true),
    );
  }

  void _onStatusChanged(
    AiVoiceSessionStatusChanged event,
    Emitter<AiVoiceSessionState> emit,
  ) {
    if (event.status == AiVoiceSessionStatus.error) {
      emit(
        state.copyWith(
          status: event.status,
          // The session's own key when it has one; a generic one otherwise.
          failureKey: _session.failureKey ?? 'ai_chat.voice_error',
        ),
      );
      level.reset();
      return;
    }

    emit(
      state.copyWith(
        status: event.status,
        // A terminal session has no card. The session emits a resolution too,
        // but ordering between two streams is not something to rely on, and a
        // card left on an ended screen is worse than one taken down twice.
        clearDocument: event.status.isTerminal,
      ),
    );
    if (event.status.isTerminal) level.reset();
  }

  Future<void> _onSettingsRequested(
    AiVoiceSessionSettingsRequested event,
    Emitter<AiVoiceSessionState> emit,
  ) => _permissions.openSettings();

  @override
  Future<void> close() async {
    if (_closed) return super.close();
    _closed = true;

    await _statusSubscription?.cancel();
    await _levelSubscription?.cancel();
    await _eventSubscription?.cancel();
    _statusSubscription = null;
    _levelSubscription = null;
    _eventSubscription = null;

    // Leaving the screen must release the microphone, whatever state the
    // session was in.
    await _session.dispose();
    level.dispose();
    ledger.dispose();

    return super.close();
  }
}
