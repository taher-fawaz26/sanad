import 'package:asset_picker/src/domain/entities/picked_asset.dart';
import 'package:asset_picker/src/domain/upload/upload_status.dart';
import 'package:equatable/equatable.dart';

/// A [PickedAsset] wrapped with generic upload lifecycle state.
///
/// This is the **foundation** future upload managers build on — it is a plain,
/// immutable value object with no networking, no I/O, and no API calls. It
/// simply *carries* the state an upload manager reads and writes:
///
/// * [status] — where the asset is in its lifecycle.
/// * [progress] — `0.0`–`1.0` transfer progress.
/// * [error] — a message describing the last failure, if any.
/// * [remoteId] / [remoteUrl] — identifiers assigned by a backend once the
///   upload completes (kept generic — no backend type is referenced).
///
/// The wrapper keeps the picker layer decoupled: acquisition produces
/// [PickedAsset]s; anything that needs upload state lifts them into
/// [UploadableAsset]s. The pure state-transition helpers ([markUploading],
/// [markUploaded], [markFailed], [markRetry]) let a manager evolve an asset
/// immutably without depending on how it is stored or transported.
class UploadableAsset extends Equatable {
  const UploadableAsset({
    required this.asset,
    this.status = UploadStatus.pending,
    this.progress = 0.0,
    this.error,
    this.remoteId,
    this.remoteUrl,
  }) : assert(
         progress >= 0.0 && progress <= 1.0,
         'progress must be between 0.0 and 1.0',
       );

  /// The underlying acquired asset.
  final PickedAsset asset;

  /// The current lifecycle state.
  final UploadStatus status;

  /// Transfer progress in the range `0.0`–`1.0`.
  final double progress;

  /// A human-readable description of the last failure, when [status] is
  /// [UploadStatus.failed]. `null` otherwise.
  final String? error;

  /// The identifier assigned by the backend once uploaded. Generic on purpose.
  final String? remoteId;

  /// The URL/location assigned by the backend once uploaded. Generic on purpose.
  final String? remoteUrl;

  /// Whether the upload finished successfully.
  bool get isUploaded => status.isUploaded;

  /// Whether a transfer is currently active.
  bool get isUploading => status.isUploading;

  /// Whether a (re)attempt is allowed from the current [status].
  bool get canStart => status.canStart;

  /// Returns a copy transitioned to [UploadStatus.uploading] with [progress].
  UploadableAsset markUploading([double progress = 0.0]) =>
      copyWith(status: UploadStatus.uploading, progress: progress, error: null);

  /// Returns a copy transitioned to [UploadStatus.uploaded] (progress `1.0`),
  /// optionally recording backend identifiers.
  UploadableAsset markUploaded({String? remoteId, String? remoteUrl}) =>
      copyWith(
        status: UploadStatus.uploaded,
        progress: 1,
        error: null,
        remoteId: remoteId,
        remoteUrl: remoteUrl,
      );

  /// Returns a copy transitioned to [UploadStatus.failed] carrying [error].
  UploadableAsset markFailed(String error) =>
      copyWith(status: UploadStatus.failed, error: error);

  /// Returns a copy transitioned to [UploadStatus.retry], clearing the error
  /// and resetting progress.
  UploadableAsset markRetry() =>
      copyWith(status: UploadStatus.retry, progress: 0, error: null);

  /// Returns a copy with selected fields overridden.
  ///
  /// Note: [error] is nullable and *is* cleared when omitted transitions call
  /// for it (the state helpers pass `error: null` explicitly); a bare
  /// `copyWith()` preserves the existing error.
  UploadableAsset copyWith({
    PickedAsset? asset,
    UploadStatus? status,
    double? progress,
    Object? error = _sentinel,
    Object? remoteId = _sentinel,
    Object? remoteUrl = _sentinel,
  }) {
    return UploadableAsset(
      asset: asset ?? this.asset,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: identical(error, _sentinel) ? this.error : error as String?,
      remoteId: identical(remoteId, _sentinel)
          ? this.remoteId
          : remoteId as String?,
      remoteUrl: identical(remoteUrl, _sentinel)
          ? this.remoteUrl
          : remoteUrl as String?,
    );
  }

  static const Object _sentinel = Object();

  @override
  List<Object?> get props => [
    asset,
    status,
    progress,
    error,
    remoteId,
    remoteUrl,
  ];

  @override
  String toString() =>
      'UploadableAsset(${asset.name}, status: $status, '
      'progress: $progress)';
}

/// Convenience helpers for turning acquired assets into upload candidates.
extension PickedAssetUploadX on PickedAsset {
  /// Lifts this asset into a pending [UploadableAsset].
  UploadableAsset toUploadable() => UploadableAsset(asset: this);
}

/// Convenience helpers for a selection of acquired assets.
extension PickedAssetListUploadX on List<PickedAsset> {
  /// Lifts every asset into a pending [UploadableAsset].
  List<UploadableAsset> toUploadable() => map((a) => a.toUploadable()).toList();
}
