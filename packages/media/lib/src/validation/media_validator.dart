import 'dart:typed_data';

import 'package:asset_picker/asset_picker.dart';
import 'package:image/image.dart' as img;
import 'package:media/src/config/media_picker_config.dart';
import 'package:media/src/models/media_validation_error.dart';

/// Validates a picked asset *before* the editor opens, so unsupported,
/// oversized, or corrupted images are rejected early with a clear reason.
///
/// Pure Dart (no Flutter, no I/O beyond the in-memory bytes) → fully unit
/// testable.
abstract final class MediaValidator {
  MediaValidator._();

  /// Returns the first failing rule, or `null` when the asset is acceptable.
  static MediaValidationError? validate(
    PickedAsset asset,
    MediaPickerConfig config,
  ) {
    if (config.imageOnly && asset.assetType != AssetType.image) {
      return MediaValidationError.unsupportedType;
    }
    if (config.imageOnly && !asset.mimeType.startsWith('image/')) {
      return MediaValidationError.unsupportedType;
    }
    if (asset.size > config.maxFileSize) {
      return MediaValidationError.tooLarge;
    }

    final bytes = asset.bytes;
    if (bytes != null && !_isDecodable(bytes)) {
      return MediaValidationError.corrupted;
    }
    return null;
  }

  /// Cheap header-based check — recognizes a decoder without a full decode.
  /// Some decoders throw on truncated buffers rather than returning null, so
  /// any throw is treated as "not decodable".
  static bool _isDecodable(Uint8List bytes) {
    try {
      return img.findDecoderForData(bytes) != null;
    } on Object {
      return false;
    }
  }
}
