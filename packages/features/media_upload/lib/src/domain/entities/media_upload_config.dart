import 'package:equatable/equatable.dart';

/// Validation/behaviour configuration for a single upload session (one grid,
/// one drop zone, one bloc instance).
class MediaUploadConfig extends Equatable {
  const MediaUploadConfig({
    this.maxFiles,
    this.maxFileSize,
    this.allowedMimeTypes = const [],
    this.allowedExtensions = const [],
    this.maxConcurrentUploads = 3,
  }) : assert(maxConcurrentUploads > 0, 'maxConcurrentUploads must be > 0');

  /// Maximum number of items allowed at once. `null` means unbounded.
  final int? maxFiles;

  /// Maximum size per file, in bytes. `null` means unbounded.
  final int? maxFileSize;

  /// Allowed MIME types (e.g. `image/jpeg`). Empty means any MIME type.
  final List<String> allowedMimeTypes;

  /// Allowed file extensions without a leading dot (e.g. `pdf`). Empty means
  /// any extension.
  final List<String> allowedExtensions;

  /// How many uploads may be in flight at once.
  final int maxConcurrentUploads;

  @override
  List<Object?> get props => [
    maxFiles,
    maxFileSize,
    allowedMimeTypes,
    allowedExtensions,
    maxConcurrentUploads,
  ];
}
