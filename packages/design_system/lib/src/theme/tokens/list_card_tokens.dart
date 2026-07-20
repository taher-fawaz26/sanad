import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:design_system/src/theme/typography/responsive_font_scale.dart';
import 'package:flutter/material.dart';

/// Visual density for entity list rows (`AppEntityListItem` / `AppListCard`).
///
/// Branch, worker, and invitation rows share one layout with small token
/// differences captured here.
enum AppEntityListItemStyle {
  /// Figma branch card (`347:14361`) — 8 dp radius, 20 dp padding, 8 dp gaps.
  compact,

  /// Figma worker / invitation cards (`1526:12324`, `1607:12287`) —
  /// 12 dp radius, 12 dp padding, 12 dp gaps, medium title.
  standard,
}

/// Resolved styling for entity list items.
@immutable
class ListCardStyleSpec {
  const ListCardStyleSpec({
    required this.padding,
    required this.contentHeight,
    required this.borderRadius,
    required this.backgroundColor,
    required this.borderColor,
    required this.contentGap,
    required this.titleCaptionGap,
    required this.titleStyle,
    required this.captionStyle,
  });

  final EdgeInsets padding;

  /// Content row height — avatar size = 40.
  final double contentHeight;

  final BorderRadius borderRadius;
  final Color backgroundColor;
  final Color borderColor;

  /// Gap between avatar, text block, badge, trailing.
  final double contentGap;

  /// Gap between title and caption.
  final double titleCaptionGap;

  final TextStyle titleStyle;
  final TextStyle captionStyle;
}

/// Token resolver for entity list items — Figma `347:14361` / `1526:12324`.
abstract final class ListCardTokens {
  ListCardTokens._();

  static ListCardStyleSpec resolve({
    required AppColors colors,
    required AppTypography typography,
    AppEntityListItemStyle style = AppEntityListItemStyle.compact,
  }) {
    final dark = colors.palettes.dark;

    return switch (style) {
      AppEntityListItemStyle.compact => ListCardStyleSpec(
        // Outer + inner Figma insets (`p-[10px]` × 2).
        padding: EdgeInsets.all(responsiveSpacing(20)),
        contentHeight: AppDimension.fieldHeightMd,
        borderRadius: BorderRadius.circular(AppDimension.radiusSm),
        backgroundColor: dark.shade50,
        borderColor: dark.shade200,
        contentGap: AppSpacing.sm,
        titleCaptionGap: AppSpacing.xs,
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
      ),
      AppEntityListItemStyle.standard => ListCardStyleSpec(
        padding: EdgeInsets.all(AppSpacing.md),
        contentHeight: AppDimension.fieldHeightMd,
        borderRadius: BorderRadius.circular(AppDimension.radiusMd),
        backgroundColor: dark.shade50,
        borderColor: dark.shade200,
        contentGap: AppSpacing.md,
        titleCaptionGap: responsiveSpacing(6),
        titleStyle: typography.regularNormal.copyWith(
          fontSize: 16.rfs,
          height: 20 / 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
          color: colors.textPrimary,
        ),
        captionStyle: typography.smallNone.copyWith(
          fontSize: 14.rfs,
          height: 14 / 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: colors.primary,
        ),
      ),
    };
  }
}
