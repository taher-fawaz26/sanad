import 'package:design_system/design_system.dart' show AppProgressBar;
import 'package:design_system/src/components/app_progress_bar.dart'
    show AppProgressBar;
import 'package:design_system/src/components/components.dart'
    show AppProgressBar;
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:flutter/material.dart';

/// Resolved styling for [AppProgressBar].
@immutable
class ProgressStyleSpec {
  const ProgressStyleSpec({
    required this.height,
    required this.borderRadius,
    required this.trackColor,
    required this.fillColor,
  });

  final double height;
  final BorderRadius borderRadius;
  final Color trackColor;
  final Color fillColor;
}

/// Figma `Views / Progress Bars` (`40:9160`) token resolver.
abstract final class ProgressTokens {
  ProgressTokens._();

  static const double height = 4;

  static ProgressStyleSpec resolve({
    required AppColors colors,
    required Brightness brightness,
  }) {
    final dark = colors.palettes.dark;
    final isDark = brightness == Brightness.dark;

    return ProgressStyleSpec(
      height: responsiveDimension(height),
      borderRadius: BorderRadius.circular(responsiveDimension(100)),
      trackColor: isDark ? dark.shade900 : dark.shade200,
      fillColor: colors.primary,
    );
  }
}
