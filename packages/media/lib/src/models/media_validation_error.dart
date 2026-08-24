/// Why a picked asset was rejected before the editor opened.
///
/// Each reason maps to a localized message key via [messageKey], so
/// consuming apps show a consistent, translated error. [tooLarge] reuses
/// `errors.media_upload.file_too_large` — the one shared "file too large"
/// message used by every upload surface in the app (see `FileSizePolicy`),
/// rather than a `media`-package-local copy of the same idea.
enum MediaValidationError {
  /// Not an image (e.g. a video or document slipped through).
  unsupportedType,

  /// Larger than the configured maximum file size.
  tooLarge,

  /// Bytes could not be decoded as a valid image.
  corrupted
  ;

  String get messageKey => switch (this) {
    MediaValidationError.unsupportedType => 'media.validation.unsupported_type',
    MediaValidationError.tooLarge => 'errors.media_upload.file_too_large',
    MediaValidationError.corrupted => 'media.validation.corrupted',
  };
}
