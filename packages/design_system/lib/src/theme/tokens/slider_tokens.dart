import 'package:design_system/src/components/app_slider.dart' show AppSlider;
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:flutter/material.dart';

/// Figma slider type (`40:7585` / coverage `194:5947`).
enum AppSliderType {
  single,
  range,
}

/// Resolved styling for [AppSlider].
@immutable
class SliderStyleSpec {
  const SliderStyleSpec({
    required this.trackHeight,
    required this.thumbRadius,
    required this.thumbBorderWidth,
    required this.trackColor,
    required this.activeColor,
    required this.thumbFillColor,
    required this.thumbBorderColor,
    required this.disabledThumbColor,
    required this.overlayRadius,
  });

  final double trackHeight;
  final double thumbRadius;
  final double thumbBorderWidth;
  final Color trackColor;
  final Color activeColor;
  final Color thumbFillColor;
  final Color thumbBorderColor;
  final Color disabledThumbColor;
  final double overlayRadius;
}

/// Figma `Controls / Sliders` (`40:7585`, coverage `194:5947`) token resolver.
///
/// Track is 8dp with rounded ends; thumb is a white circle with a primary
/// border and soft drop shadow (not a solid primary fill).
abstract final class SliderTokens {
  SliderTokens._();

  static const double trackHeight = 8;
  static const double thumbRadius = 12;
  static const double thumbBorderWidth = 1.5;

  /// Figma Gray/200 (`#EAECF0`) — inactive track.
  static const Color _inactiveTrackLight = Color(0xFFEAECF0);

  static SliderStyleSpec resolve({
    required AppColors colors,
    required Brightness brightness,
  }) {
    final dark = colors.palettes.dark;
    final isDark = brightness == Brightness.dark;

    return SliderStyleSpec(
      trackHeight: responsiveDimension(trackHeight),
      thumbRadius: responsiveDimension(thumbRadius),
      thumbBorderWidth: responsiveDimension(thumbBorderWidth),
      trackColor: isDark ? dark.shade900 : _inactiveTrackLight,
      activeColor: colors.primary,
      thumbFillColor: colors.surface,
      thumbBorderColor: colors.primary,
      disabledThumbColor: isDark ? dark.shade700 : dark.shade300,
      overlayRadius: responsiveDimension(thumbRadius * 1.5),
    );
  }

  static SliderThemeData sliderTheme({
    required AppColors colors,
    required Brightness brightness,
  }) {
    final spec = resolve(colors: colors, brightness: brightness);

    return SliderThemeData(
      trackHeight: spec.trackHeight,
      activeTrackColor: spec.activeColor,
      inactiveTrackColor: spec.trackColor,
      thumbColor: spec.thumbFillColor,
      disabledThumbColor: spec.disabledThumbColor,
      overlayColor: spec.activeColor.withValues(alpha: 0.12),
      overlayShape: RoundSliderOverlayShape(overlayRadius: spec.overlayRadius),
      trackShape: const RoundedRectSliderTrackShape(),
      thumbShape: _AppSliderThumbShape(
        radius: spec.thumbRadius,
        borderWidth: spec.thumbBorderWidth,
        fillColor: spec.thumbFillColor,
        borderColor: spec.thumbBorderColor,
      ),
    );
  }
}

/// White circular thumb with primary stroke — Figma `194:5954`.
class _AppSliderThumbShape extends SliderComponentShape {
  const _AppSliderThumbShape({
    required this.radius,
    required this.borderWidth,
    required this.fillColor,
    required this.borderColor,
  });

  final double radius;
  final double borderWidth;
  final Color fillColor;
  final Color borderColor;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      Size.fromRadius(radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    // Soft shadow matching Figma Shadow/md.
    final shadowPaint = Paint()
      ..color = const Color(0x1A101828)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas
      ..drawCircle(center.translate(0, 1), radius, shadowPaint)
      ..drawCircle(center, radius, Paint()..color = fillColor)
      ..drawCircle(
        center,
        radius - borderWidth / 2,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth,
      );
  }
}
