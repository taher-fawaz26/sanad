import 'package:asset_picker/asset_picker.dart';
import 'package:media_upload/src/domain/entities/media_upload_config.dart';
import 'package:media_upload/src/domain/failures/media_upload_failure.dart';

/// Pure, synchronous validation against a [MediaUploadConfig] — runs before
/// any item is enqueued for upload, so invalid files fail immediately
/// without consuming a concurrency slot.
abstract final class MediaUploadValidator {
  MediaUploadValidator._();

  /// Validates a single [asset]. [currentCount] is the number of items
  /// already present (excluding the one being validated) — used to enforce
  /// [MediaUploadConfig.maxFiles].
  static MediaUploadFailure? validateAsset({
    required PickedAsset asset,
    required MediaUploadConfig config,
    required int currentCount,
  }) {
    final maxFiles = config.maxFiles;
    if (maxFiles != null && currentCount >= maxFiles) {
      return MaxFilesExceededFailure(maxFiles: maxFiles);
    }

    final maxFileSize = config.maxFileSize;
    if (maxFileSize != null && asset.size > maxFileSize) {
      return FileTooLargeFailure(maxFileSize: maxFileSize);
    }

    if (config.allowedMimeTypes.isNotEmpty &&
        !config.allowedMimeTypes.contains(asset.mimeType)) {
      return const UnsupportedTypeFailure();
    }

    if (config.allowedExtensions.isNotEmpty &&
        !config.allowedExtensions.contains(asset.extension.toLowerCase())) {
      return const UnsupportedTypeFailure();
    }

    return null;
  }

  /// Whether another item may be added given [currentCount] existing items.
  static bool canAddMore({
    required MediaUploadConfig config,
    required int currentCount,
  }) {
    final maxFiles = config.maxFiles;
    return maxFiles == null || currentCount < maxFiles;
  }
}
