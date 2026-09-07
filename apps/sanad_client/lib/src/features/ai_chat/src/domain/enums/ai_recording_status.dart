/// The recorded-audio state machine.
///
/// One linear path with two exits, so every transition is checkable:
///
/// ```text
/// idle -> requestingPermission -> recording -> encoding -> preview -> (sent)
///                |                    |                       |
///                v                    v                       v
///        permissionDenied         interrupted              (deleted -> idle)
/// ```
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

  /// The microphone is live and samples are arriving.
  recording,

  /// Stopped; the encoder is finalising the file.
  encoding,

  /// A finished take exists and can be played, deleted, or attached.
  preview,

  /// The take was lost — a call arrived, the route changed, or the recorder
  /// failed. Carries a localization key.
  failed
  ;

  /// Whether the microphone is currently capturing.
  bool get isCapturing => this == AiRecordingStatus.recording;

  /// Whether the composer should show the recording bar rather than the
  /// normal text row.
  bool get occupiesComposer =>
      this == AiRecordingStatus.recording ||
      this == AiRecordingStatus.encoding ||
      this == AiRecordingStatus.preview;
}
