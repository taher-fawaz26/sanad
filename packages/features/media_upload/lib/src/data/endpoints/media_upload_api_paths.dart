/// Backend endpoint for the shared, feature-agnostic media-upload pipeline.
abstract final class MediaUploadApiPaths {
  MediaUploadApiPaths._();

  /// `POST` — multipart upload of a single file. Returns
  /// `{id, originalName, fileName, mimeType, size, type, url, createdAt}`.
  static const String uploadSingle = 'media/upload-single';
}
