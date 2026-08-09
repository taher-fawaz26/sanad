import 'package:asset_picker/asset_picker.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:media_upload/src/domain/entities/uploaded_media.dart';

/// The single upload boundary every feature shares — `POST
/// /media/upload-single`. Feature-specific attach/replace/delete operations
/// happen afterwards, outside this package, using [UploadedMedia.mediaId].
abstract interface class MediaUploadRepository {
  /// Uploads [asset], reporting `0.0`–`1.0` progress via [onProgress].
  ///
  /// [uploadKey] identifies this transfer for cancellation — pass the
  /// owning `MediaUploadItem.localId` so [cancelUpload] can target it.
  TaskEither<Failure, UploadedMedia> upload({
    required String uploadKey,
    required PickedAsset asset,
    void Function(double progress)? onProgress,
  });

  /// Cancels an in-flight upload started with [uploadKey], if any.
  void cancelUpload(String uploadKey);
}
