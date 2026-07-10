import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma status badge variant (`40:10689`, `40:10672`).
enum AppStatusBadgeType {
  success,
  alert,
  warning,
  info,
}

@immutable
class StatusBadgeStyleSpec {
  const StatusBadgeStyleSpec({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderRadius,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.textStyle,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final BorderRadius borderRadius;
  final double horizontalPadding;
  final double verticalPadding;
  final TextStyle textStyle;
}

/// Figma `Views / Status Badges` (`40:10689`, `40:10672`) token resolver.
abstract final class StatusBadgeTokens {
  StatusBadgeTokens._();

  static StatusBadgeStyleSpec resolve({
    required AppStatusBadgeType type,
    required AppTypography typography,
    required AppColors colors,
  }) {
    final (background, foreground) = switch (type) {
      AppStatusBadgeType.success =>
        (colors.successContainer, colors.onSuccessContainer),
      AppStatusBadgeType.alert =>
        (colors.errorContainer, colors.onErrorContainer),
      AppStatusBadgeType.warning =>
        (colors.warningContainer, colors.onWarningContainer),
      AppStatusBadgeType.info => (colors.infoContainer, colors.onInfoContainer),
    };

    return StatusBadgeStyleSpec(
      backgroundColor: background,
      foregroundColor: foreground,
      borderRadius: BorderRadius.circular(AppDimension.radiusSm),
      horizontalPadding: AppSpacing.lg,
      verticalPadding: AppSpacing.sm,
      textStyle: typography.smallNormal.copyWith(
        fontWeight: FontWeight.w600,
        color: foreground,
      ),
    );
  }
}
