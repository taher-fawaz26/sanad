import 'package:equatable/equatable.dart';

/// Visual state of a single [MediaUploadTileData] — mirrors (but does not
/// depend on) `media_upload`'s `MediaUploadStatus`, so this package stays
/// feature-independent.
enum MediaUploadTileStatus { pending, uploading, success, failure }

/// Display-only projection of an upload item, passed in by whatever feature
/// owns the `MediaUploadBloc`. Contains no networking types and no business
/// logic — purely what the tile needs to render.
class MediaUploadTileData extends Equatable {
  const MediaUploadTileData({
    required this.id,
    this.previewUrl,
    this.fileName,
    this.progress = 0.0,
    this.status = MediaUploadTileStatus.pending,
    this.errorMessage,
  });

  /// Stable identifier used to address retry/remove/replace callbacks.
  final String id;

  /// Remote or local (`file://`) image URL to preview, if any.
  final String? previewUrl;

  final String? fileName;

  /// `0.0`–`1.0`, meaningful while [status] is
  /// [MediaUploadTileStatus.uploading].
  final double progress;

  final MediaUploadTileStatus status;

  /// Shown when [status] is [MediaUploadTileStatus.failure].
  final String? errorMessage;

  @override
  List<Object?> get props => [
    id,
    previewUrl,
    fileName,
    progress,
    status,
    errorMessage,
  ];
}
