/// Resolves a best-effort MIME type from a file extension.
///
/// A tiny, dependency-free lookup so the package does not pull in a full MIME
/// database. Providers use it as a fallback when the platform does not report
/// a MIME type. Unknown extensions resolve to `application/octet-stream`.
abstract final class AssetMimeResolver {
  AssetMimeResolver._();

  static const String fallback = 'application/octet-stream';

  static const Map<String, String> _byExtension = {
    // Images
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'bmp': 'image/bmp',
    'heic': 'image/heic',
    'heif': 'image/heif',
    // Video
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
    'avi': 'video/x-msvideo',
    'mkv': 'video/x-matroska',
    'webm': 'video/webm',
    // Audio
    'mp3': 'audio/mpeg',
    'm4a': 'audio/mp4',
    'wav': 'audio/wav',
    'aac': 'audio/aac',
    'ogg': 'audio/ogg',
    // Documents
    'pdf': 'application/pdf',
    'doc': 'application/msword',
    'docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls': 'application/vnd.ms-excel',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'ppt': 'application/vnd.ms-powerpoint',
    'pptx':
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'txt': 'text/plain',
    'csv': 'text/csv',
    'rtf': 'application/rtf',
    'zip': 'application/zip',
  };

  /// Returns the MIME type for [fileName]'s extension, or [fallback].
  static String fromFileName(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot == fileName.length - 1) return fallback;
    return fromExtension(fileName.substring(dot + 1));
  }

  /// Returns the MIME type for a bare [extension] (with or without a dot).
  static String fromExtension(String extension) {
    final normalized = extension.replaceFirst('.', '').toLowerCase();
    return _byExtension[normalized] ?? fallback;
  }
}
