/// The recorded-audio state machine.
///
/// One linear path with two exits, so every transition is checkable:
///
/// ```text
/// idle -> requestingPermission -> recording -> encoding -> preview -> (sent)
///                |                    |  ^                   |
///                v                    v  |                   v
///        permissionDenied     lockedRecording           (deleted -> idle)
///                                     |
///                                     v
///                                interrupted
/// ```
///
/// [recording] and [lockedRecording] are the same capture with two different
/// *interactions*: the first is held under the user's finger and ends when they
/// let go, the second continues hands-free until they explicitly stop it. The
/// recorder does not know the difference — nothing is called on it when a take
/// locks — which is why this is one extra enum value rather than a second
/// recording path.
///
/// This is *recorded audio*, a message attachment. Live voice is a separate
/// subsystem with its own lifecycle — see `AiVoiceSessionStatus`.
enum AiRecordingStatus {
  /// Nothing is being recorded and there is no take to preview.
  idle,

  /// Waiting on the microphone permission decision.
  requestingPermission,

  /// The permission was refused. The UI offers the settings path when
  /// `permanentlyDenied` accompanies this.
  permissionDenied,

  /// The microphone is live and samples are arriving, under a held finger.
  /// Releasing ends the take.
  recording,

  /// The microphone is live and samples are arriving, hands-free. Releasing the
  /// finger does nothing; only an explicit stop or delete ends the take.
  lockedRecording,

  /// Stopped; the encoder is finalising the file.
  encoding,

  /// A finished take exists and can be played, deleted, or attached.
  preview,

  /// The take was lost — a call arrived, the route changed, or the recorder
  /// failed. Carries a localization key.
  failed
  ;

  /// Whether the microphone is currently capturing.
  ///
  /// Both capture states, so every guard built on this — the duration cap in
  /// `AiComposerBloc`'s sample listener, the stop guard, backgrounding cleanup,
  /// and dictation's mutual-exclusion check — covers a locked take without a
  /// new call site.
  bool get isCapturing =>
      this == AiRecordingStatus.recording ||
      this == AiRecordingStatus.lockedRecording;

  /// Whether a take exists or is being made, so another may not start and the
  /// composer is not in its ordinary idle shape.
  bool get occupiesComposer =>
      isCapturing ||
      this == AiRecordingStatus.encoding ||
      this == AiRecordingStatus.preview;

  /// Whether the composer shows a live recording surface rather than the text
  /// row.
  ///
  /// Narrower than [occupiesComposer], which also covers [preview] — and
  /// preview shows the finished take with its own controls, not the recording
  /// surface.
  bool get showsRecordingRow =>
      isCapturing || this == AiRecordingStatus.encoding;

  /// Whether a turn may not be sent yet.
  ///
  /// Everything before a take exists blocks: a permission prompt is up, the
  /// microphone is open, or the encoder still owes us a file. [preview] is
  /// deliberately absent — a finished take is exactly what send is for — and so
  /// are [idle], [permissionDenied] and [failed], which have nothing pending
  /// behind them.
  bool get blocksSend =>
      isCapturing ||
      this == AiRecordingStatus.requestingPermission ||
      this == AiRecordingStatus.encoding;
}
