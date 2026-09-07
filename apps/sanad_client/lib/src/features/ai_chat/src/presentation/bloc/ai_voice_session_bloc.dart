import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/enums/ai_voice_session_status.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_permission_gateway.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_voice_session.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/level_history.dart';

part 'ai_voice_session_event.dart';
part 'ai_voice_session_state.dart';

/// Carries the live microphone level for the voice screen.
///
/// The third member of the same family as `ActiveStreamController` and
/// `RecordingLevelController`, for the same reason: a level that ticks with
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
  }) : _session = session,
       _permissions = permissions,
       level = level ?? VoiceLevelController(),
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
    on<AiVoiceSessionBackgrounded>(
      _onBackgrounded,
      transformer: sequential(),
    );
    on<AiVoiceSessionStatusChanged>(_onStatusChanged);
    on<AiVoiceSessionSettingsRequested>(_onSettingsRequested);

    _statusSubscription = _session.status.listen(
      (status) => add(AiVoiceSessionStatusChanged(status)),
    );
    _levelSubscription = _session.inputLevel.listen(
      (value) => this.level.add(value),
    );
  }

  /// Live microphone level. Read directly by the waveform; never state.
  final VoiceLevelController level;

  final AiVoiceSession _session;
  final AiPermissionGateway _permissions;

  StreamSubscription<AiVoiceSessionStatus>? _statusSubscription;
  StreamSubscription<double>? _levelSubscription;

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

    emit(state.copyWith(status: event.status));
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
    _statusSubscription = null;
    _levelSubscription = null;

    // Leaving the screen must release the microphone, whatever state the
    // session was in.
    await _session.dispose();
    level.dispose();

    return super.close();
  }
}
