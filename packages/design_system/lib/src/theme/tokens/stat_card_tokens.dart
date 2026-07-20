import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Resolved styling for KPI/stat cards — Figma `kpi-card` (`1563:11021`).
@immutable
class StatCardStyleSpec {
  const StatCardStyleSpec({
    required this.padding,
    required this.borderRadius,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconCircleSize,
    required this.contentGap,
    required this.textGap,
    required this.countStyle,
    required this.labelStyle,
  });

  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final Color backgroundColor;
  final Color borderColor;

  /// Diameter of the leading icon circle — Figma `size-[48px]`.
  final double iconCircleSize;

  /// Gap between icon circle and text group — Figma `gap-[12px]`.
  final double contentGap;

  /// Gap between count and label text — Figma `gap-[2px]`.
  final double textGap;

  final TextStyle countStyle;
  final TextStyle labelStyle;
}

/// Figma KPI/stat card (`1563:11021`) token resolver.
abstract final class StatCardTokens {
  StatCardTokens._();

  static StatCardStyleSpec resolve({
    required AppColors colors,
    required AppTypography typography,
  }) {
    return StatCardStyleSpec(
      padding: EdgeInsets.all(responsiveSpacing(16)),
      borderRadius: BorderRadius.circular(responsiveDimension(16)),
      backgroundColor: colors.white,
      borderColor: colors.border,
      iconCircleSize: responsiveDimension(48),
      contentGap: AppSpacing.md,
      textGap: 2,
      countStyle: typography.regularNormal.copyWith(
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      labelStyle: typography.smallNormal.copyWith(
        fontWeight: FontWeight.w500,
        color: colors.textSecondary,
      ),
    );
  }
}
