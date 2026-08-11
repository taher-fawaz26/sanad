import 'package:asset_picker/asset_picker.dart';
import 'package:equatable/equatable.dart';
import 'package:media_upload/src/domain/entities/media_upload_status.dart';
import 'package:media_upload/src/domain/failures/media_upload_failure.dart';

/// A single file's upload lifecycle — local selection through to a
/// backend-confirmed [MediaUploadStatus.success].
///
/// Every item's state is independent: a batch of four items can be
/// `success, uploading, failure, success` at once, and a failure here never
/// mutates any other item.
class MediaUploadItem extends Equatable {
  const MediaUploadItem({
    required this.localId,
    required this.asset,
    this.mediaId,
    this.url,
    this.originalName,
    this.fileName,
    this.mimeType,
    this.size,
    this.progress = 0.0,
    this.status = MediaUploadStatus.pending,
    this.failure,
  }) : assert(
         progress >= 0.0 && progress <= 1.0,
         'progress must be between 0.0 and 1.0',
       );

  /// Seeds an already-`success` item for media that's already on the
  /// backend (e.g. pre-filling an edit form from a service's existing
  /// `media`) — no local file/upload involved, so [asset] is a placeholder
  /// never used for retry/replace (those actions are hidden for
  /// already-successful items).
  factory MediaUploadItem.remote({
    required String mediaId,
    required String url,
    String? fileName,
    String? mimeType,
    int? size,
  }) => MediaUploadItem(
    localId: mediaId,
    asset: PickedAsset(
      name: fileName ?? mediaId,
      path: '',
      mimeType: mimeType ?? 'image/jpeg',
      size: size ?? 0,
      assetType: AssetType.image,
    ),
    mediaId: mediaId,
    url: url,
    originalName: fileName,
    fileName: fileName,
    mimeType: mimeType,
    size: size,
    status: MediaUploadStatus.success,
    progress: 1,
  );

  /// Stable client-side identifier — generated once when the item is added,
  /// used to address it for retry/remove/replace regardless of upload
  /// outcome (unlike [mediaId], which only exists after success).
  final String localId;

  /// The locally picked asset backing this item.
  final PickedAsset asset;

  /// Backend identifier — only set once the upload succeeds. Mandatory to
  /// preserve for feature-level attach/replace calls.
  final String? mediaId;
  final String? url;
  final String? originalName;
  final String? fileName;
  final String? mimeType;
  final int? size;

  /// Transfer progress in `0.0`–`1.0`, meaningful while [status] is
  /// [MediaUploadStatus.uploading].
  final double progress;

  final MediaUploadStatus status;

  /// Populated when [status] is [MediaUploadStatus.failure].
  final MediaUploadFailure? failure;

  bool get isPending => status.isPending;

  bool get isUploading => status.isUploading;

  bool get isSuccess => status.isSuccess;

  bool get isFailure => status.isFailure;

  MediaUploadItem copyWith({
    PickedAsset? asset,
    Object? mediaId = _sentinel,
    Object? url = _sentinel,
    Object? originalName = _sentinel,
    Object? fileName = _sentinel,
    Object? mimeType = _sentinel,
    Object? size = _sentinel,
    double? progress,
    MediaUploadStatus? status,
    Object? failure = _sentinel,
  }) {
    return MediaUploadItem(
      localId: localId,
      asset: asset ?? this.asset,
      mediaId: identical(mediaId, _sentinel)
          ? this.mediaId
          : mediaId as String?,
      url: identical(url, _sentinel) ? this.url : url as String?,
      originalName: identical(originalName, _sentinel)
          ? this.originalName
          : originalName as String?,
      fileName: identical(fileName, _sentinel)
          ? this.fileName
          : fileName as String?,
      mimeType: identical(mimeType, _sentinel)
          ? this.mimeType
          : mimeType as String?,
      size: identical(size, _sentinel) ? this.size : size as int?,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      failure: identical(failure, _sentinel)
          ? this.failure
          : failure as MediaUploadFailure?,
    );
  }

  static const Object _sentinel = Object();

  @override
  List<Object?> get props => [
    localId,
    asset,
    mediaId,
    url,
    originalName,
    fileName,
    mimeType,
    size,
    progress,
    status,
    failure,
  ];

  @override
  String toString() =>
      'MediaUploadItem(localId: $localId, status: $status, '
      'progress: $progress)';
}
