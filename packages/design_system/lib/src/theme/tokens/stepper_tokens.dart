import 'package:design_system/design_system.dart' show AppStepper;
import 'package:design_system/src/components/app_stepper.dart' show AppStepper;
import 'package:design_system/src/components/components.dart' show AppStepper;
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma stepper size tier (`40:7513`).
enum AppStepperSize {
  large,
  small,
}

/// Resolved styling for [AppStepper].
@immutable
class StepperStyleSpec {
  const StepperStyleSpec({
    required this.largeWidth,
    required this.smallWidth,
    required this.largeHeight,
    required this.smallHeight,
    required this.borderRadius,
    required this.borderColor,
    required this.largeIconSize,
    required this.smallIconSize,
    required this.largeIconInset,
    required this.smallIconInset,
    required this.valueStyle,
    required this.decrementColor,
    required this.incrementColor,
    required this.disabledIconColor,
  });

  final double largeWidth;
  final double smallWidth;
  final double largeHeight;
  final double smallHeight;
  final BorderRadius borderRadius;
  final Color borderColor;
  final double largeIconSize;
  final double smallIconSize;
  final double largeIconInset;
  final double smallIconInset;
  final TextStyle valueStyle;
  final Color decrementColor;
  final Color incrementColor;
  final Color disabledIconColor;

  double width(AppStepperSize size) =>
      size == AppStepperSize.large ? largeWidth : smallWidth;

  double height(AppStepperSize size) =>
      size == AppStepperSize.large ? largeHeight : smallHeight;

  double iconSize(AppStepperSize size) =>
      size == AppStepperSize.large ? largeIconSize : smallIconSize;

  double iconInset(AppStepperSize size) =>
      size == AppStepperSize.large ? largeIconInset : smallIconInset;
}

/// Figma `Controls / Steppers` (`40:7513`) token resolver.
abstract final class StepperTokens {
  StepperTokens._();

  static const double largeWidth = 124;
  static const double smallWidth = 100;
  static const double largeHeight = 48;
  static const double smallHeight = 32;
  static const double borderRadius = 60;
  static const double largeIconSize = 24;
  static const double smallIconSize = 16;
  static const double largeIconInset = 15;
  static const double smallIconInset = 11;

  static StepperStyleSpec resolve({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    final dark = colors.palettes.dark;
    final isDark = brightness == Brightness.dark;

    return StepperStyleSpec(
      largeWidth: responsiveDimension(largeWidth),
      smallWidth: responsiveDimension(smallWidth),
      largeHeight: responsiveDimension(largeHeight),
      smallHeight: responsiveDimension(smallHeight),
      borderRadius: BorderRadius.circular(responsiveDimension(borderRadius)),
      borderColor: isDark ? dark.shade800 : dark.shade200,
      largeIconSize: responsiveDimension(largeIconSize),
      smallIconSize: responsiveDimension(smallIconSize),
      largeIconInset: responsiveDimension(largeIconInset),
      smallIconInset: responsiveDimension(smallIconInset),
      valueStyle: typography.labelLarge.copyWith(
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
      ),
      decrementColor: isDark ? dark.shade600 : dark.shade300,
      incrementColor: colors.primary,
      disabledIconColor: isDark ? dark.shade700 : dark.shade300,
    );
  }
}
