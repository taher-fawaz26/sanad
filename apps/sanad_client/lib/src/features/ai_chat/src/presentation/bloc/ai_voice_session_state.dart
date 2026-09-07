part of 'ai_voice_session_bloc.dart';

/// The voice session as the screen sees it.
///
/// Note what is *not* here: the microphone level. It ticks with every audio
/// frame and lives in [VoiceLevelController], so the waveform can move without
/// rebuilding the controls around it.
final class AiVoiceSessionState extends Equatable {
  /// Creates a voice state.
  const AiVoiceSessionState({
    this.status = AiVoiceSessionStatus.idle,
    this.isMuted = false,
    this.failureKey,
    this.canOpenSettings = false,
  });

  /// Where the session is.
  final AiVoiceSessionStatus status;

  /// Whether the microphone is muted. The stream stays open either way.
  final bool isMuted;

  /// A localization key when [status] is `error`. Never prose.
  final String? failureKey;

  /// Whether the failure is one the system settings screen can fix.
  final bool canOpenSettings;

  /// Whether the assistant can be interrupted right now.
  bool get canInterrupt => status == AiVoiceSessionStatus.speaking;

  /// Whether a start button should be offered.
  bool get canStart => !status.isActive;

  /// Returns a copy with the given fields replaced.
  ///
  /// [clearFailure] exists because `??` cannot express "set this back to
  /// null", and a failure that could never be cleared would outlive a retry.
  AiVoiceSessionState copyWith({
    AiVoiceSessionStatus? status,
    bool? isMuted,
    String? failureKey,
    bool clearFailure = false,
    bool? canOpenSettings,
  }) => AiVoiceSessionState(
    status: status ?? this.status,
    isMuted: isMuted ?? this.isMuted,
    failureKey: clearFailure ? null : (failureKey ?? this.failureKey),
    canOpenSettings: !clearFailure && (canOpenSettings ?? this.canOpenSettings),
  );

  @override
  List<Object?> get props => [status, isMuted, failureKey, canOpenSettings];
}
