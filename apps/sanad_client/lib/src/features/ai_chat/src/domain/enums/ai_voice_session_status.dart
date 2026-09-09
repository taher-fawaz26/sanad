/// The live-voice session lifecycle.
///
/// ```text
/// idle -> connecting -> listening <-> processing -> speaking
///                           ^                          |
///                           +------ barge-in ----------+
///
/// speaking|processing -> awaitingInteraction -> processing -> speaking
///
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

  /// The assistant asked something a card answers, and is waiting for a tap.
  ///
  /// The one state the original eight could not express. `listening` tells the
  /// user to speak, `processing` says the assistant is thinking, `speaking`
  /// says it is talking — and none of those is true while a time-slot card is
  /// on screen with the microphone deliberately released.
  ///
  /// Releasing the microphone is the point: leaving capture running would put
  /// barge-in detection and silence detection in a race with the user reading
  /// a card, and a cough would end a turn that had not started.
  awaitingInteraction,

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
  /// barge-in possible. It stops during [awaitingInteraction] for the opposite
  /// reason: the answer is coming from a finger, not a voice.
  bool get capturesAudio =>
      this == AiVoiceSessionStatus.listening ||
      this == AiVoiceSessionStatus.speaking;

  /// Whether the session is doing anything at all.
  ///
  /// [awaitingInteraction] counts: the session is alive and holding the
  /// conversation open, which is what stops the start button offering to begin
  /// a session that has not ended.
  bool get isActive =>
      this == AiVoiceSessionStatus.connecting ||
      this == AiVoiceSessionStatus.listening ||
      this == AiVoiceSessionStatus.processing ||
      this == AiVoiceSessionStatus.speaking ||
      this == AiVoiceSessionStatus.awaitingInteraction;

  /// Whether no further transition will happen without a restart.
  bool get isTerminal =>
      this == AiVoiceSessionStatus.ended || this == AiVoiceSessionStatus.error;
}
