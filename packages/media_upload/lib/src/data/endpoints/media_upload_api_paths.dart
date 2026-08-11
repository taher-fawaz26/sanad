/// Backend endpoints for the shared, feature-agnostic media-upload pipeline.
/// Confirmed against the live OpenAPI spec
/// (`https://dev-api.trysanad.us/api/docs-json`).
abstract final class MediaUploadApiPaths {
  MediaUploadApiPaths._();

  /// `POST` — multipart upload of a single file. Returns
  /// `{id, originalName, fileName, mimeType, size, type, url, createdAt}`.
  static const String uploadSingle = 'media/upload-single';

  /// `DELETE` — provider-only, and only for media the caller themselves
  /// uploaded (`MediaService.deleteMedia` checks `ownerId`).
  static String delete(String id) => 'media/$id';
}
