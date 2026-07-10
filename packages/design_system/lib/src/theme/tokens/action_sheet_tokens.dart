import 'package:design_system/design_system.dart' show AppActionSheet;
import 'package:design_system/src/components/app_action_sheet.dart' show AppActionSheet;
import 'package:design_system/src/components/components.dart' show AppActionSheet;
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Resolved styling for [AppActionSheet].
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
}

/// Figma `Views / Action Sheets` (`40:9109`) token resolver.
abstract final class ActionSheetTokens {
  ActionSheetTokens._();

  static const double topRadius = 16;
  static const double horizontalPadding = 24;
  static const double itemHeight = 56;
  static const double barrierOpacity = 0.7;

  static ActionSheetStyleSpec resolve({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    final dark = colors.palettes.dark;
    final isDark = brightness == Brightness.dark;

    return ActionSheetStyleSpec(
      barrierColor: dark.shade950.withValues(alpha: barrierOpacity),
      surfaceColor: isDark ? dark.shade900 : colors.white,
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
        color: colors.textSecondary,
      ),
      dividerColor: isDark ? dark.shade800 : dark.shade100,
    );
  }
}
