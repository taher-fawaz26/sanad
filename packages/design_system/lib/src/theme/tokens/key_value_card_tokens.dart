import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:design_system/src/theme/typography/responsive_font_scale.dart';
import 'package:flutter/material.dart';

/// Resolved styling for [AppKeyValueCard].
@immutable
class KeyValueCardStyleSpec {
  const KeyValueCardStyleSpec({
    required this.height,
    required this.horizontalPadding,
    required this.borderRadius,
    required this.backgroundColor,
    required this.borderColor,
    required this.titleStyle,
    required this.valueStyle,
  });

  final double height;
  final double horizontalPadding;
  final BorderRadius borderRadius;
  final Color backgroundColor;
  final Color borderColor;
  final TextStyle titleStyle;
  final TextStyle valueStyle;
}

/// Figma schedule row card (`347:14680`) token resolver.
abstract final class KeyValueCardTokens {
  KeyValueCardTokens._();

  static const double height = 48;
  static const double horizontalPadding = 15;
  static const double borderRadius = 12;

  static KeyValueCardStyleSpec resolve({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    final sky = colors.palettes.sky;
    final main = colors.palettes.main;
    final isDark = brightness == Brightness.dark;

    return KeyValueCardStyleSpec(
      height: responsiveDimension(height),
      horizontalPadding: responsiveSpacing(horizontalPadding),
      borderRadius: BorderRadius.circular(responsiveDimension(borderRadius)),
      backgroundColor: isDark ? sky.shade900 : sky.shade50,
      borderColor: isDark ? sky.shade700 : sky.shade200,
      titleStyle: typography.regularNormal.copyWith(
        fontSize: 16.rfs,
        height: 20 / 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colors.textPrimary,
      ),
      valueStyle: typography.regularNormal.copyWith(
        fontSize: 16.rfs,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: main.shade700,
      ),
    );
  }
}
