import 'package:design_system/design_system.dart' show AppTableCell, AppTableRow;
import 'package:design_system/src/components/components.dart' show AppTableCell, AppTableRow;
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
    required this.heightWithCaption,
    required this.titleStyle,
    required this.captionStyle,
    required this.textGap,
  });

  final double height;
  final double heightWithCaption;
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
    required this.avatarSize,
    required this.trailingTextStyle,
    required this.trailingIconColor,
  });

  final double height;
  final double horizontalPadding;
  final double leadingGap;
  final double trailingGap;
  final Color backgroundColor;
  final double leadingIconSize;
  final double avatarSize;
  final TextStyle trailingTextStyle;
  final Color trailingIconColor;
}

/// Figma table row leading slot (`40:9256`).
enum AppTableLeading {
  none,
  avatar,
  icon,
}

/// Figma table row trailing slot (`40:9256`).
enum AppTableTrailing {
  none,
  text,
  icon,
  button,
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

/// Figma `_Partials / Tables` (`194:3008`) and `Views / Tables` (`40:9256`).
abstract final class TableTokens {
  TableTokens._();

  static AppTableTheme themeExtension({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    return AppTableTheme(
      cell: resolveCell(
        colors: colors,
        typography: typography,
      ),
      row: resolveRow(
        colors: colors,
        typography: typography,
        brightness: brightness,
      ),
    );
  }

  static TableCellStyleSpec resolveCell({
    required AppColors colors,
    required AppTypography typography,
  }) {
    return TableCellStyleSpec(
      height: AppDimension.fieldHeightMd,
      heightWithCaption: AppDimension.fieldHeightMd,
      titleStyle: typography.regularNormal.copyWith(
        color: colors.textPrimary,
        height: 20 / 16,
      ),
      captionStyle: typography.smallNormal.copyWith(
        color: colors.textMuted,
        height: 16 / 14,
      ),
      textGap: AppSpacing.xs,
    );
  }

  static TableRowStyleSpec resolveRow({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    return TableRowStyleSpec(
      height: AppDimension.tableRowHeight,
      horizontalPadding: AppSpacing.xxl,
      leadingGap: AppSpacing.md,
      trailingGap: AppSpacing.md,
      backgroundColor: colors.surface,
      leadingIconSize: AppDimension.iconMenu,
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
