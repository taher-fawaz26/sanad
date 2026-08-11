/// Lifecycle state of a single `MediaUploadItem`.
///
/// Deliberately independent per item — one item's `failure` never affects
/// the `status` of any other item in a batch.
enum MediaUploadStatus {
  /// Queued but not yet uploading (validated, waiting for a concurrency
  /// slot).
  pending,

  /// Bytes are currently being transferred.
  uploading,

  /// Uploaded successfully; `mediaId`/`url` are populated.
  success,

  /// Validation or upload failed; `error` describes why.
  failure
  ;

  bool get isPending => this == MediaUploadStatus.pending;

  bool get isUploading => this == MediaUploadStatus.uploading;

  bool get isSuccess => this == MediaUploadStatus.success;

  bool get isFailure => this == MediaUploadStatus.failure;
}
