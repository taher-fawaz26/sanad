/// Backend endpoint for the shared authenticated media-upload pipeline.
abstract final class MediaUploadApiPaths {
  MediaUploadApiPaths._();

  /// `POST` — multipart upload of a single file. Returns `{id, url, ...}`.
  ///
  /// Shared by every authenticated upload flow in this feature (cover/logo
  /// images, legal documents) — upload first to get a `mediaId`, then
  /// PATCH/PUT that id into the resource it belongs to.
  static const String uploadSingle = 'media/upload-single';
}
