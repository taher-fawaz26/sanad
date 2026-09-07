/// Where dictation is.
///
/// Deliberately its own axis, separate from `AiRecordingStatus`. The two look
/// alike from a distance — both open the microphone — but they are different
/// capabilities with different outputs: dictation produces **text in the
/// composer**, a recording produces **a file attached to a message**. Merging
/// them into one "audio" state would make every consumer ask which mode it is
/// in, and would tie two lifecycles that must be able to refuse each other.
enum AiSpeechStatus {
  /// Nothing is listening.
  idle,

  /// Waiting on the microphone / speech-recognition grant.
  requestingPermission,

  /// Permission is in hand and the recognizer is being brought up.
  starting,

  /// The recognizer is live and partial results are arriving.
  listening,

  /// The user stopped; the recognizer is settling on its final answer.
  finalizing,

  /// A final transcript landed in the composer, where it is now ordinary
  /// editable text. Cleared by the next composer action.
  completed,

  /// Recognition failed. The reason travels as a notice, not in this enum.
  error
  ;

  /// Whether the recognizer currently holds the microphone.
  ///
  /// [completed] and [error] are *outcomes*: the microphone is already back.
  bool get isActive =>
      this == starting || this == listening || this == finalizing;

  /// Whether the composer should show the dictation bar instead of the input
  /// row. The same shape as `AiRecordingStatus.occupiesComposer`, so the
  /// composer asks both the same question.
  bool get occupiesComposer => isActive;
}
