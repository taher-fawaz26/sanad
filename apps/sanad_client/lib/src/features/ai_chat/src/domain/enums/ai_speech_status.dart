/// Where dictation is.
///
/// The composer's one and only microphone axis. Dictation produces **text in
/// the composer** and nothing else: no file, no attachment, nothing uploaded.
/// (A live-voice *session* has its own status type, for a capability that
/// holds the microphone for a whole conversation rather than a phrase.)
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
  /// row.
  bool get occupiesComposer => isActive;
}
