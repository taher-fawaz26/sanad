import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

/// A crop overlay that masks everything outside a circle, used for avatar
/// editing (square crop, circular preview). Overrides only the three drawing
/// hooks the base [EditorCropLayerPainter] composes, so it stays in sync with
/// the base class's rotation-aware mask rect handling.
class CircleCropLayerPainter extends EditorCropLayerPainter {
  const CircleCropLayerPainter();

  @override
  void paintMask(
    Canvas canvas,
    Rect rect,
    ExtendedImageCropLayerPainter painter,
  ) {
    canvas
      ..saveLayer(rect, Paint())
      ..drawRect(rect, Paint()..color = painter.maskColor)
      ..drawOval(painter.cropRect, Paint()..blendMode = BlendMode.clear)
      ..restore();
  }

  @override
  void paintLines(
    Canvas canvas,
    Size size,
    ExtendedImageCropLayerPainter painter,
  ) {
    canvas.drawOval(
      painter.cropRect,
      Paint()
        ..color = painter.lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = painter.lineHeight,
    );
  }

  @override
  void paintCorners(
    Canvas canvas,
    Size size,
    ExtendedImageCropLayerPainter painter,
  ) {
    // No corner handles for a circular crop.
  }
}
