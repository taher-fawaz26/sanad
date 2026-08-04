/// Why a picked asset was rejected before the editor opened.
///
/// Each reason maps to a localized message key under `media.validation.*`
/// via [messageKey], so consuming apps show a consistent, translated error.
enum MediaValidationError {
  /// Not an image (e.g. a video or document slipped through).
  unsupportedType,

  /// Larger than the configured maximum file size.
  tooLarge,

  /// Bytes could not be decoded as a valid image.
  corrupted;

  String get messageKey => switch (this) {
    MediaValidationError.unsupportedType =>
      'media.validation.unsupported_type',
    MediaValidationError.tooLarge => 'media.validation.too_large',
    MediaValidationError.corrupted => 'media.validation.corrupted',
  };
}
