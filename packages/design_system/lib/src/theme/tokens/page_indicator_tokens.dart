import 'package:design_system/design_system.dart' show AppPageIndicator;
import 'package:design_system/src/components/app_page_indicator.dart' show AppPageIndicator;
import 'package:design_system/src/components/components.dart' show AppPageIndicator;
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:flutter/material.dart';

/// Resolved styling for [AppPageIndicator].
@immutable
class PageIndicatorStyleSpec {
  const PageIndicatorStyleSpec({
    required this.dotSize,
    required this.activeColor,
    required this.inactiveColor,
    required this.dotSpacing,
  });

  final double dotSize;
  final Color activeColor;
  final Color inactiveColor;
  final double dotSpacing;
}

/// Figma `Controls / Page Controls: Dot` (`40:7639`) token resolver.
abstract final class PageIndicatorTokens {
  PageIndicatorTokens._();

  static const double dotSize = 8;
  static const double dotSpacing = 8;

  static PageIndicatorStyleSpec resolve({
    required AppColors colors,
    required Brightness brightness,
  }) {
    final dark = colors.palettes.dark;
    final isDark = brightness == Brightness.dark;

    return PageIndicatorStyleSpec(
      dotSize: responsiveDimension(dotSize),
      activeColor: isDark ? colors.white : colors.primary,
      inactiveColor: isDark
          ? colors.white.withValues(alpha: 0.3)
          : dark.shade200,
      dotSpacing: responsiveDimension(dotSpacing),
    );
  }
}
