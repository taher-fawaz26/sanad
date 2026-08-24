/// The lifecycle state of an asset that is being (or will be) uploaded.
///
/// This enum is a **pure model** — it carries no networking, no I/O, and no
/// business rules. It exists so that a future upload manager (chat attachments,
/// KYC, profile images, branch/worker documents, …) has a shared vocabulary to
/// consume without every feature reinventing its own status enum.
enum UploadStatus {
  /// Queued but not started.
  pending,

  /// A local, pre-upload document-type check is running (e.g. OCR/scanner
  /// classification) before bytes are transferred.
  validating,

  /// Bytes are currently being transferred.
  uploading,

  /// Completed successfully.
  uploaded,

  /// Failed and is not (yet) scheduled to retry.
  failed,

  /// Marked for another attempt after a failure.
  retry
  ;

  /// Whether this is a final success state.
  bool get isUploaded => this == UploadStatus.uploaded;

  /// Whether a pre-upload document-type check is currently running.
  bool get isValidating => this == UploadStatus.validating;

  /// Whether a transfer is currently active.
  bool get isUploading => this == UploadStatus.uploading;

  /// Whether the asset failed its last attempt.
  bool get isFailed => this == UploadStatus.failed;

  /// Whether the asset is waiting to (re)start — [pending] or [retry].
  bool get isWaiting =>
      this == UploadStatus.pending || this == UploadStatus.retry;

  /// Whether a (re)attempt is allowed from this state.
  bool get canStart =>
      this == UploadStatus.pending ||
      this == UploadStatus.retry ||
      this == UploadStatus.failed;

  /// Whether this is a terminal state (no further transition expected without
  /// an explicit retry).
  bool get isTerminal =>
      this == UploadStatus.uploaded || this == UploadStatus.failed;
}
