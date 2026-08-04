import 'package:equatable/equatable.dart';

/// The crop geometry offered by the editor.
enum MediaCropShape {
  /// Free rectangle; [MediaEditorConfig.aspectRatio] may still constrain it.
  free,

  /// Locked 1:1 square.
  square,
}

/// The encoded output format of the processed image.
enum MediaOutputFormat { jpg, png }

/// Declarative configuration for the edit + process steps.
///
/// Presets [MediaEditorConfig.cover] and [MediaEditorConfig.avatar] cover the
/// common identity-header cases; any feature can construct a bespoke config.
class MediaEditorConfig extends Equatable {
  const MediaEditorConfig({
    this.cropShape = MediaCropShape.free,
    this.aspectRatio,
    this.circleOverlay = false,
    this.maxWidth,
    this.maxHeight,
    this.compressQuality = 85,
    this.outputFormat = MediaOutputFormat.jpg,
  }) : assert(
         compressQuality >= 0 && compressQuality <= 100,
         'compressQuality must be between 0 and 100',
       );

  /// Wide banner preset: free crop (optionally ratio-locked), capped at
  /// 1920×1080, JPEG.
  const MediaEditorConfig.cover({
    double? aspectRatio = 16 / 9,
    int compressQuality = 82,
  }) : this(
         cropShape: MediaCropShape.free,
         aspectRatio: aspectRatio,
         maxWidth: 1920,
         maxHeight: 1080,
         compressQuality: compressQuality,
       );

  /// Profile/logo preset: locked square with a circular preview overlay,
  /// capped at 1024×1024, JPEG.
  const MediaEditorConfig.avatar({int compressQuality = 85})
    : this(
        cropShape: MediaCropShape.square,
        aspectRatio: 1,
        circleOverlay: true,
        maxWidth: 1024,
        maxHeight: 1024,
        compressQuality: compressQuality,
      );

  final MediaCropShape cropShape;

  /// Locked crop aspect ratio (width / height). `null` = fully free.
  final double? aspectRatio;

  /// Draw a circular mask over the (square) crop area — a circular preview
  /// while the stored image stays square.
  final bool circleOverlay;

  /// Maximum output dimensions; the processor downscales to fit, preserving
  /// aspect ratio. `null` = no cap.
  final int? maxWidth;
  final int? maxHeight;

  /// Output encoding quality (0–100), applied to JPEG.
  final int compressQuality;

  final MediaOutputFormat outputFormat;

  String get outputMimeType =>
      outputFormat == MediaOutputFormat.png ? 'image/png' : 'image/jpeg';

  String get outputExtension =>
      outputFormat == MediaOutputFormat.png ? 'png' : 'jpg';

  @override
  List<Object?> get props => [
    cropShape,
    aspectRatio,
    circleOverlay,
    maxWidth,
    maxHeight,
    compressQuality,
    outputFormat,
  ];
}
