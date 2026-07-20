import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:design_system/src/theme/typography/responsive_font_scale.dart';
import 'package:flutter/material.dart';

/// Figma `Views / Badges: Status: Rounded` (`40:10689`) variant.
enum AppStatusBadgeType {
  /// Green — `Status=Success`.
  success,

  /// Red — `Status=Alert`.
  alert,

  /// Yellow — `Status=Warning`.
  warning,

  /// Blue — `Status=Info`.
  info,
}

/// Figma status badge density.
enum AppStatusBadgeSize {
  /// Standalone badge — 16 px label, py 8 (`40:10689`).
  medium,

  /// Branch list badge — 14 px label, height 24 (`347:14361`).
  compact,

  /// Worker / invitation list badge — 12 px label, height 20
  /// (`1526:12324`, `1607:12287`).
  dense,
}

@immutable
class StatusBadgeStyleSpec {
  const StatusBadgeStyleSpec({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderRadius,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.height,
    required this.textStyle,
    this.borderColor,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final BorderRadius borderRadius;
  final double horizontalPadding;
  final double verticalPadding;
  final double? height;
  final TextStyle textStyle;

  /// Optional stroke — Figma worker badge (`1526:12324`) uses primary border.
  final Color? borderColor;
}

/// Figma `Views / Badges: Status: Rounded` (`40:10689`) token resolver.
abstract final class StatusBadgeTokens {
  StatusBadgeTokens._();

  static StatusBadgeStyleSpec resolve({
    required AppStatusBadgeType type,
    required AppTypography typography,
    required AppColors colors,
    AppStatusBadgeSize size = AppStatusBadgeSize.medium,
    bool outlined = false,
  }) {
    final (background, foreground) = switch (type) {
      AppStatusBadgeType.success => (
          colors.successContainer,
          colors.onSuccessContainer,
        ),
      AppStatusBadgeType.alert => (
          colors.errorContainer,
          colors.onErrorContainer,
        ),
      AppStatusBadgeType.warning => (
          colors.warningContainer,
          colors.onWarningContainer,
        ),
      AppStatusBadgeType.info => (
          colors.infoContainer,
          colors.onInfoContainer,
        ),
    };

    final (height, fontSize, lineHeight) = switch (size) {
      AppStatusBadgeSize.medium => (null, 16.0, 1.0),
      AppStatusBadgeSize.compact => (AppDimension.iconMenu, 14.0, 16 / 14),
      AppStatusBadgeSize.dense => (responsiveDimension(20), 12.0, 16 / 12),
    };

    return StatusBadgeStyleSpec(
      backgroundColor: background,
      foregroundColor: foreground,
      borderRadius: BorderRadius.circular(AppDimension.radiusSm),
      horizontalPadding: AppSpacing.lg,
      verticalPadding: AppSpacing.sm,
      height: height,
      borderColor: outlined ? colors.primary : null,
      textStyle: typography.regularNormal.copyWith(
        fontSize: fontSize.rfs,
        height: lineHeight,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: foreground,
      ),
    );
  }
}
