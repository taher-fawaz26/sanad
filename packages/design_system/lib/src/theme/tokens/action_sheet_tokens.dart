import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/overlay_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Resolved styling for `AppActionList`.
@immutable
class ActionSheetStyleSpec {
  const ActionSheetStyleSpec({
    required this.barrierColor,
    required this.surfaceColor,
    required this.topRadius,
    required this.horizontalPadding,
    required this.titleStyle,
    required this.itemHeight,
    required this.itemStyle,
    required this.cancelStyle,
    required this.dividerColor,
    required this.leadingIconSize,
    required this.itemHorizontalGap,
    required this.leadingLabelInset,
  });

  final Color barrierColor;
  final Color surfaceColor;
  final BorderRadius topRadius;
  final double horizontalPadding;
  final TextStyle titleStyle;
  final double itemHeight;
  final TextStyle itemStyle;
  final TextStyle cancelStyle;
  final Color dividerColor;

  /// Size of the optional leading icon slot (Figma: 24dp).
  final double leadingIconSize;

  /// Horizontal gap between the leading icon and the label.
  final double itemHorizontalGap;

  /// Left inset of the label when a leading icon is present
  /// (Figma: `60px` label offset vs. `24px` icon offset).
  final double leadingLabelInset;
}

/// Figma `Views / Action Sheets` (`40:9109`) token resolver.
abstract final class ActionSheetTokens {
  ActionSheetTokens._();

  static const double topRadius = 16;
  static const double horizontalPadding = 24;
  static const double itemHeight = 56;
  static const double barrierOpacity = OverlayTokens.scrimOpacity;
  static const double leadingIconSize = 24;
  static const double leadingLabelInset = 60;

  static ActionSheetStyleSpec resolve({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;

    return ActionSheetStyleSpec(
      barrierColor: OverlayTokens.scrimColor(),
      surfaceColor: isDark ? OverlayTokens.ink800 : colors.white,
      topRadius: BorderRadius.vertical(
        top: Radius.circular(responsiveDimension(topRadius)),
      ),
      horizontalPadding: responsiveDimension(horizontalPadding),
      titleStyle: typography.title3.copyWith(
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
      ),
      itemHeight: responsiveDimension(itemHeight),
      itemStyle: typography.regularNormal.copyWith(
        color: colors.textPrimary,
      ),
      cancelStyle: typography.regularNormal.copyWith(
        color: isDark ? OverlayTokens.ink600 : OverlayTokens.chromeDark,
      ),
      dividerColor: isDark ? OverlayTokens.ink700 : OverlayTokens.chromeLighter,
      leadingIconSize: responsiveDimension(leadingIconSize),
      // horizontalPadding(24) + leadingIconSize(24) + itemHorizontalGap(12)
      // = leadingLabelInset(60), matching Figma's icon/label offsets exactly.
      itemHorizontalGap: AppSpacing.md,
      leadingLabelInset: responsiveDimension(leadingLabelInset),
    );
  }
}
