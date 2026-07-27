/// The logical kind of an acquired asset.
///
/// [AssetType] is a *domain* classification — it is deliberately decoupled
/// from any concrete picker plugin. Providers translate their native results
/// into one of these values so that features never reason about MIME strings
/// or file extensions directly.
enum AssetType {
  /// A raster or vector image (jpg, png, webp, heic, …).
  image,

  /// A video clip (mp4, mov, …). Future-ready — most providers do not yet
  /// emit videos, but the type exists so the API never has to change.
  video,

  /// An audio recording (mp3, m4a, wav, …). Future-ready.
  audio,

  /// A PDF document.
  pdf,

  /// A non-PDF office document (doc, docx, xls, xlsx, ppt, txt, …).
  document,

  /// Any file — used when the caller does not want the package to constrain
  /// the selection by type.
  any
  ;

  /// The canonical file extensions (without a leading dot) associated with
  /// this type. Used both for default provider filtering and for validation.
  ///
  /// [any] intentionally returns an empty set — it matches everything and is
  /// never used to *restrict* a selection.
  Set<String> get defaultExtensions => switch (this) {
    AssetType.image => const {
      'jpg',
      'jpeg',
      'png',
      'webp',
      'heic',
      'gif',
      'bmp',
    },
    AssetType.video => const {'mp4', 'mov', 'avi', 'mkv', 'webm'},
    AssetType.audio => const {'mp3', 'm4a', 'wav', 'aac', 'ogg'},
    AssetType.pdf => const {'pdf'},
    AssetType.document => const {
      'doc',
      'docx',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
      'txt',
      'csv',
      'rtf',
    },
    AssetType.any => const {},
  };

  /// Resolves an [AssetType] from a bare file [extension] (case-insensitive,
  /// with or without a leading dot). Falls back to [AssetType.any] when the
  /// extension is unknown.
  static AssetType fromExtension(String extension) {
    final normalized = extension.replaceFirst('.', '').toLowerCase();
    for (final type in AssetType.values) {
      if (type == AssetType.any) continue;
      if (type.defaultExtensions.contains(normalized)) return type;
    }
    return AssetType.any;
  }

  /// Resolves an [AssetType] from a MIME type such as `image/png` or
  /// `application/pdf`. Falls back to [AssetType.any] when unknown.
  static AssetType fromMimeType(String mimeType) {
    final mime = mimeType.toLowerCase();
    if (mime == 'application/pdf') return AssetType.pdf;
    if (mime.startsWith('image/')) return AssetType.image;
    if (mime.startsWith('video/')) return AssetType.video;
    if (mime.startsWith('audio/')) return AssetType.audio;
    if (mime.startsWith('application/') || mime.startsWith('text/')) {
      return AssetType.document;
    }
    return AssetType.any;
  }
}
