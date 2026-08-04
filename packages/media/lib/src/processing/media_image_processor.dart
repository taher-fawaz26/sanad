import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:media/src/config/media_editor_config.dart';

/// The immutable input to [MediaImageProcessor.process].
///
/// Plain data only (no closures) so it can cross the `compute` isolate
/// boundary. Crop coordinates are in the source image's pixel space *after*
/// EXIF orientation is baked — the same space `extended_image`'s
/// `getCropRect()` reports.
@immutable
class MediaProcessRequest {
  const MediaProcessRequest({
    required this.bytes,
    required this.rotationDegrees,
    required this.flipHorizontal,
    required this.flipVertical,
    required this.compressQuality,
    required this.png,
    this.cropX,
    this.cropY,
    this.cropWidth,
    this.cropHeight,
    this.maxWidth,
    this.maxHeight,
  });

  final Uint8List bytes;
  final int? cropX;
  final int? cropY;
  final int? cropWidth;
  final int? cropHeight;
  final int rotationDegrees;
  final bool flipHorizontal;
  final bool flipVertical;
  final int? maxWidth;
  final int? maxHeight;
  final int compressQuality;
  final bool png;

  bool get hasCrop =>
      cropWidth != null &&
      cropHeight != null &&
      cropWidth! > 0 &&
      cropHeight! > 0;
}

/// The processed image bytes plus final pixel dimensions.
@immutable
class ProcessedImage {
  const ProcessedImage({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}

/// Thrown when the source bytes cannot be decoded (should be caught earlier
/// by validation, but guarded here too).
class MediaProcessingException implements Exception {
  const MediaProcessingException(this.message);
  final String message;
  @override
  String toString() => 'MediaProcessingException: $message';
}

/// Runs the post-edit pipeline entirely with the pure-Dart `image` package on
/// a background isolate: decode → bake EXIF orientation → crop → flip →
/// rotate → resize-to-fit → encode/compress.
///
/// Order matters: orientation is baked first so pixel coordinates match what
/// the editor displayed; cropping happens in that space; rotation/flip apply
/// after; downscaling and compression last.
abstract final class MediaImageProcessor {
  MediaImageProcessor._();

  static Future<ProcessedImage> process(MediaProcessRequest request) =>
      compute(_run, request);

  /// Builds a [MediaProcessRequest] from editor output + config, translating
  /// a floating-point crop [cropRect] (l/t/w/h) into integer pixel bounds.
  static MediaProcessRequest requestFrom({
    required Uint8List bytes,
    required MediaEditorConfig config,
    double? cropLeft,
    double? cropTop,
    double? cropWidth,
    double? cropHeight,
    int rotationDegrees = 0,
    bool flipHorizontal = false,
    bool flipVertical = false,
  }) {
    return MediaProcessRequest(
      bytes: bytes,
      cropX: cropLeft?.round(),
      cropY: cropTop?.round(),
      cropWidth: cropWidth?.round(),
      cropHeight: cropHeight?.round(),
      rotationDegrees: rotationDegrees,
      flipHorizontal: flipHorizontal,
      flipVertical: flipVertical,
      maxWidth: config.maxWidth,
      maxHeight: config.maxHeight,
      compressQuality: config.compressQuality,
      png: config.outputFormat == MediaOutputFormat.png,
    );
  }

  static ProcessedImage _run(MediaProcessRequest req) {
    img.Image? decoded;
    try {
      decoded = img.decodeImage(req.bytes);
    } on Object {
      decoded = null;
    }
    if (decoded == null) {
      throw const MediaProcessingException('Could not decode image bytes.');
    }
    var image = decoded;

    // 1. Normalize EXIF orientation so subsequent pixel ops are predictable
    //    and the user never sees a rotated iPhone photo.
    image = img.bakeOrientation(image);

    // 2. Crop (copyCrop clamps out-of-range rects internally).
    if (req.hasCrop) {
      image = img.copyCrop(
        image,
        x: req.cropX ?? 0,
        y: req.cropY ?? 0,
        width: req.cropWidth!,
        height: req.cropHeight!,
      );
    }

    // 3. Flip.
    if (req.flipHorizontal) image = img.flipHorizontal(image);
    if (req.flipVertical) image = img.flipVertical(image);

    // 4. Rotate.
    if (req.rotationDegrees % 360 != 0) {
      image = img.copyRotate(image, angle: req.rotationDegrees);
    }

    // 5. Downscale to fit the configured caps, preserving aspect ratio.
    image = _resizeToFit(image, req.maxWidth, req.maxHeight);

    // 6. Encode + compress.
    final bytes = req.png
        ? img.encodePng(image)
        : img.encodeJpg(image, quality: req.compressQuality);

    return ProcessedImage(
      bytes: bytes,
      width: image.width,
      height: image.height,
    );
  }

  static img.Image _resizeToFit(img.Image image, int? maxW, int? maxH) {
    if (maxW == null && maxH == null) return image;
    final overW = maxW != null && image.width > maxW;
    final overH = maxH != null && image.height > maxH;
    if (!overW && !overH) return image;

    final scale = [
      if (maxW != null) maxW / image.width,
      if (maxH != null) maxH / image.height,
    ].reduce((a, b) => a < b ? a : b);

    return img.copyResize(
      image,
      width: (image.width * scale).round(),
      height: (image.height * scale).round(),
      interpolation: img.Interpolation.average,
    );
  }
}
