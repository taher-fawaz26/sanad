import 'dart:io';

import 'package:asset_picker/src/domain/entities/picked_asset.dart';
import 'package:asset_picker/src/domain/enums/asset_type.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Post-validation image compression stage.
///
/// Used only when `AssetPickerOptions.enforceSizeBeforeCompression` is set: the
/// provider acquires the untouched original (so the validator gates on its true
/// size), and this stage re-encodes the *already-validated* asset to JPEG. An
/// oversized original can therefore never be shrunk into eligibility, while a
/// valid pick is still compressed before it leaves the picker.
abstract class AssetImageCompressor {
  /// Returns a compressed copy of [asset], or [asset] unchanged when it is not
  /// an image or cannot be decoded (e.g. SVG/vector data).
  Future<PickedAsset> compress(PickedAsset asset, {required int quality});
}

/// Default [AssetImageCompressor] backed by the pure-Dart `image` package.
///
/// The decode/encode runs on a background isolate (`compute`) so a large image
/// never janks the UI thread. Any failure (unreadable file, undecodable bytes)
/// falls back to the original asset — validation has already guaranteed it is
/// within the size limit, so a failed compression must never drop the pick.
class ImagePackageAssetCompressor implements AssetImageCompressor {
  const ImagePackageAssetCompressor();

  @override
  Future<PickedAsset> compress(
    PickedAsset asset, {
    required int quality,
  }) async {
    if (asset.assetType != AssetType.image) return asset;
    try {
      final source = asset.bytes ?? await File(asset.path).readAsBytes();
      final jpeg = await compute(
        _encodeInIsolate,
        _JpegEncodeRequest(source, quality),
      );
      if (jpeg == null) return asset;
      return asset.copyWith(
        name: _toJpgName(asset.name),
        bytes: jpeg,
        mimeType: 'image/jpeg',
        size: jpeg.length,
      );
    } on Object {
      return asset;
    }
  }

  /// Decode-then-`encodeJpg`, exposed for direct (isolate-free) unit testing.
  /// Returns `null` when [source] cannot be decoded as an image.
  static Uint8List? encodeJpeg(Uint8List source, int quality) {
    try {
      final decoded = img.decodeImage(source);
      if (decoded == null) return null;
      return img.encodeJpg(decoded, quality: quality);
    } on Object {
      // `image` may throw (not just return null) on truncated/undecodable
      // data — treat any decode/encode failure as "cannot compress".
      return null;
    }
  }

  /// Swaps any extension on [name] for `.jpg` (the re-encoded output format).
  static String toJpgName(String name) => _toJpgName(name);
}

/// `compute`-payload wrapper (a plain data class so it crosses the isolate
/// boundary).
@immutable
class _JpegEncodeRequest {
  const _JpegEncodeRequest(this.source, this.quality);

  final Uint8List source;
  final int quality;
}

/// Top-level isolate entry point for [ImagePackageAssetCompressor.compress].
Uint8List? _encodeInIsolate(_JpegEncodeRequest req) =>
    ImagePackageAssetCompressor.encodeJpeg(req.source, req.quality);

String _toJpgName(String name) {
  final dot = name.lastIndexOf('.');
  final base = dot <= 0 ? name : name.substring(0, dot);
  return '$base.jpg';
}
