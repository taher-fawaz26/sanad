/// The live-voice session lifecycle.
///
/// ```text
/// idle -> connecting -> listening <-> processing -> speaking
///                           ^                          |
///                           +------ barge-in ----------+
/// any -> ending -> ended        any -> error
/// ```
///
/// Deliberately *not* shared with `AiRecordingStatus`. A voice session is a
/// continuous conversation that owns the microphone for its whole life and
/// produces no message attachment; a recording produces exactly one file and
/// then releases the microphone. Collapsing the two would force every state
/// consumer to ask which mode it is in.
enum AiVoiceSessionStatus {
  /// Not started, or fully torn down and restartable.
  idle,

  /// Acquiring the microphone and the audio session.
  connecting,

  /// The microphone is live and the user is being listened to.
  listening,

  /// The user stopped talking; the assistant is "thinking".
  processing,

  /// The assistant is talking. Interruptible.
  speaking,

  /// Tearing down.
  ending,

  /// Finished. Terminal.
  ended,

  /// Something failed. Terminal until restarted; carries a localization key.
  error
  ;

  /// Whether the microphone should be capturing in this state.
  ///
  /// Capture continues during [speaking] on purpose — that is what makes
  /// barge-in possible.
  bool get capturesAudio =>
      this == AiVoiceSessionStatus.listening ||
      this == AiVoiceSessionStatus.speaking;

  /// Whether the session is doing anything at all.
  bool get isActive =>
      this == AiVoiceSessionStatus.connecting ||
      this == AiVoiceSessionStatus.listening ||
      this == AiVoiceSessionStatus.processing ||
      this == AiVoiceSessionStatus.speaking;

  /// Whether no further transition will happen without a restart.
  bool get isTerminal =>
      this == AiVoiceSessionStatus.ended || this == AiVoiceSessionStatus.error;
}
