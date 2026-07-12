import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:design_system/src/theme/typography/responsive_font_scale.dart';
import 'package:flutter/material.dart';

/// Resolved styling for [AppTableCell].
@immutable
class TableCellStyleSpec {
  const TableCellStyleSpec({
    required this.height,
    required this.titleStyle,
    required this.captionStyle,
    required this.textGap,
  });

  /// Figma `_Partials / Tables` content height — 40 dp.
  final double height;
  final TextStyle titleStyle;
  final TextStyle captionStyle;
  final double textGap;
}

/// Resolved styling for [AppTableRow].
@immutable
class TableRowStyleSpec {
  const TableRowStyleSpec({
    required this.height,
    required this.horizontalPadding,
    required this.leadingGap,
    required this.trailingGap,
    required this.backgroundColor,
    required this.leadingIconSize,
    required this.trailingIconSize,
    required this.avatarSize,
    required this.trailingTextStyle,
    required this.trailingIconColor,
  });

  /// Figma row height — 64 dp.
  final double height;
  final double horizontalPadding;
  final double leadingGap;
  final double trailingGap;
  final Color backgroundColor;

  /// Leading icon size — 24 dp (`Left=Icon`).
  final double leadingIconSize;

  /// Trailing icon size — 24 dp (`Right=Icon`).
  final double trailingIconSize;

  /// Leading avatar size — 40 dp (`Left=Avatar`).
  final double avatarSize;
  final TextStyle trailingTextStyle;
  final Color trailingIconColor;
}

/// Figma table row leading slot (`40:9256`).
enum AppTableLeading {
  /// `Left=Empty`
  none,

  /// `Left=Avatar` — 40 dp.
  avatar,

  /// `Left=Icon` — 24 dp.
  icon,
}

/// Figma table row trailing slot (`40:9256`).
enum AppTableTrailing {
  /// `Right=No Actions`
  none,

  /// `Right=Text` — primary medium link label.
  text,

  /// `Right=Icon` — 24 dp glyph.
  icon,

  /// `Right=Button` — small primary pill.
  button,

  /// `Right=Switch`
  switchControl,
}

@immutable
class AppTableTheme extends ThemeExtension<AppTableTheme> {
  const AppTableTheme({
    required this.cell,
    required this.row,
  });

  final TableCellStyleSpec cell;
  final TableRowStyleSpec row;

  @override
  AppTableTheme copyWith({
    TableCellStyleSpec? cell,
    TableRowStyleSpec? row,
  }) {
    return AppTableTheme(
      cell: cell ?? this.cell,
      row: row ?? this.row,
    );
  }

  @override
  AppTableTheme lerp(covariant AppTableTheme? other, double t) {
    if (other == null) {
      return this;
    }
    return t < 0.5 ? this : other;
  }
}

extension AppTableThemeX on BuildContext {
  AppTableTheme get appTableTheme =>
      Theme.of(this).extension<AppTableTheme>()!;
}

/// Figma `_Partials / Tables` (`40:8360`) and `Views / Tables` (`40:9256`).
abstract final class TableTokens {
  TableTokens._();

  static AppTableTheme themeExtension({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    return AppTableTheme(
      cell: resolveCell(colors: colors, typography: typography),
      row: resolveRow(colors: colors, typography: typography),
    );
  }

  static TableCellStyleSpec resolveCell({
    required AppColors colors,
    required AppTypography typography,
  }) {
    return TableCellStyleSpec(
      height: AppDimension.fieldHeightMd,
      titleStyle: typography.regularNormal.copyWith(
        fontSize: 16.rfs,
        height: 20 / 16,
        fontWeight: FontWeight.w400,
        color: colors.textPrimary,
      ),
      captionStyle: typography.smallNormal.copyWith(
        fontSize: 14.rfs,
        height: 16 / 14,
        fontWeight: FontWeight.w400,
        color: colors.textMuted,
      ),
      textGap: AppSpacing.xs,
    );
  }

  static TableRowStyleSpec resolveRow({
    required AppColors colors,
    required AppTypography typography,
  }) {
    return TableRowStyleSpec(
      height: AppDimension.tableRowHeight,
      horizontalPadding: AppSpacing.xxl,
      leadingGap: AppSpacing.md,
      trailingGap: AppSpacing.md,
      backgroundColor: colors.surface,
      leadingIconSize: AppDimension.iconMenu,
      trailingIconSize: AppDimension.iconMenu,
      avatarSize: AppDimension.fieldHeightMd,
      trailingTextStyle: typography.regularNormal.copyWith(
        fontSize: 16.rfs,
        height: 20 / 16,
        fontWeight: FontWeight.w500,
        color: colors.primary,
      ),
      trailingIconColor: colors.textPrimary,
    );
  }
}
