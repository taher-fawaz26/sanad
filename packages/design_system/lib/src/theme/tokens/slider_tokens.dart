import 'package:design_system/design_system.dart' show AppSlider;
import 'package:design_system/src/components/app_slider.dart' show AppSlider;
import 'package:design_system/src/components/components.dart' show AppSlider;
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:flutter/material.dart';

/// Figma slider type (`40:7585`).
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
    required this.trackColor,
    required this.activeColor,
    required this.thumbColor,
    required this.disabledThumbColor,
    required this.overlayRadius,
  });

  final double trackHeight;
  final double thumbRadius;
  final Color trackColor;
  final Color activeColor;
  final Color thumbColor;
  final Color disabledThumbColor;
  final double overlayRadius;
}

/// Figma `Controls / Sliders` (`40:7585`) token resolver.
abstract final class SliderTokens {
  SliderTokens._();

  static const double trackHeight = 4;
  static const double thumbRadius = 12;

  static SliderStyleSpec resolve({
    required AppColors colors,
    required Brightness brightness,
  }) {
    final dark = colors.palettes.dark;
    final isDark = brightness == Brightness.dark;

    return SliderStyleSpec(
      trackHeight: responsiveDimension(trackHeight),
      thumbRadius: responsiveDimension(thumbRadius),
      trackColor: isDark ? dark.shade900 : dark.shade200,
      activeColor: colors.primary,
      thumbColor: colors.primary,
      disabledThumbColor: isDark ? dark.shade700 : dark.shade300,
      overlayRadius: responsiveDimension(thumbRadius),
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
      thumbColor: spec.thumbColor,
      disabledThumbColor: spec.disabledThumbColor,
      overlayShape: RoundSliderOverlayShape(overlayRadius: spec.overlayRadius),
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: spec.thumbRadius),
    );
  }
}
