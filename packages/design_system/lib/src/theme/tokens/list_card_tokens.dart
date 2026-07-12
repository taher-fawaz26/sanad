import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:design_system/src/theme/typography/responsive_font_scale.dart';
import 'package:flutter/material.dart';

/// Resolved styling for list cards — Figma `347:14378`.
@immutable
class ListCardStyleSpec {
  const ListCardStyleSpec({
    required this.padding,
    required this.contentHeight,
    required this.borderRadius,
    required this.backgroundColor,
    required this.borderColor,
    required this.contentGap,
    required this.titleStyle,
    required this.captionStyle,
  });

  /// Outer + inner Figma insets (`p-[10px]` × 2) flattened.
  final EdgeInsets padding;

  /// Content row height — avatar / `_Partials / Tables` = 40.
  final double contentHeight;

  final BorderRadius borderRadius;
  final Color backgroundColor;
  final Color borderColor;

  /// Gap between avatar, text, badge — Figma `gap-[8px]`.
  final double contentGap;

  final TextStyle titleStyle;
  final TextStyle captionStyle;
}

/// Figma branch list card (`347:14378`) token resolver.
abstract final class ListCardTokens {
  ListCardTokens._();

  static ListCardStyleSpec resolve({
    required AppColors colors,
    required AppTypography typography,
  }) {
    return ListCardStyleSpec(
      padding: EdgeInsets.all(responsiveSpacing(20)),
      contentHeight: AppDimension.fieldHeightMd,
      borderRadius: BorderRadius.circular(AppDimension.radiusSm),
      backgroundColor: colors.background,
      borderColor: colors.border,
      contentGap: AppSpacing.sm,
      titleStyle: typography.regularNormal.copyWith(
        fontSize: 16.rfs,
        height: 20 / 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colors.textPrimary,
      ),
      captionStyle: typography.smallNormal.copyWith(
        fontSize: 14.rfs,
        height: 16 / 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colors.primary,
      ),
    );
  }
}
