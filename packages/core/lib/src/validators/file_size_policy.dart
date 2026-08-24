/// Application-wide maximum file/image size policy — the single source of
/// truth for the upload size limit enforced across every file/image picker
/// and upload flow in the app (Add/Edit Service images, Profile/Cover
/// image, registration and legal-document uploads, and any future one).
///
/// Uses the actual byte length (`File.length()` / `XFile.length()`), never a
/// displayed decimal-MB approximation: 5 MiB = 5 * 1024 * 1024 bytes.
///
/// A feature may request a *stricter* (smaller) limit of its own via
/// [effectiveLimit] — it may never exceed [maxBytes]. Consumers that pick
/// files (`asset_picker`'s `DefaultAssetValidator`) or stage them for upload
/// (`media_upload`'s `MediaUploadValidator`) apply this clamp themselves, so
/// a call site that forgets to pass a size limit — or passes one looser than
/// the global maximum — still can never accept an oversized file.
abstract final class FileSizePolicy {
  FileSizePolicy._();

  /// The global maximum: 5 MiB, expressed in bytes.
  static const int maxBytes = 5 * 1024 * 1024;

  /// Whether [sizeInBytes] is within the global maximum.
  static bool isValid(int sizeInBytes) => sizeInBytes <= maxBytes;

  /// The effective limit for a feature that also declares its own
  /// [featureLimitBytes] — the smaller of the two always wins, so a
  /// feature-specific rule can tighten but never loosen the global maximum.
  static int effectiveLimit([int? featureLimitBytes]) {
    if (featureLimitBytes == null || featureLimitBytes > maxBytes) {
      return maxBytes;
    }
    return featureLimitBytes;
  }
}
