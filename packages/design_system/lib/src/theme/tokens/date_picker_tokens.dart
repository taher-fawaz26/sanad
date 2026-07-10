import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Resolved styling for one calendar day cell.
@immutable
class CalendarDayStyleSpec {
  const CalendarDayStyleSpec({
    required this.size,
    required this.borderRadius,
    required this.defaultBackgroundColor,
    required this.activeBackgroundColor,
    required this.defaultTextColor,
    required this.activeTextColor,
    required this.textStyle,
  });

  final double size;
  final BorderRadius borderRadius;
  final Color defaultBackgroundColor;
  final Color activeBackgroundColor;
  final Color defaultTextColor;
  final Color activeTextColor;
  final TextStyle textStyle;
}

/// Resolved styling for date picker surfaces.
@immutable
class DatePickerStyleSpec {
  const DatePickerStyleSpec({
    required this.surfaceColor,
    required this.headerColor,
    required this.headerTextStyle,
    required this.dayStyle,
    required this.selectedDayColor,
    required this.selectedDayTextColor,
    required this.todayBorderColor,
    required this.dividerColor,
    required this.borderRadius,
    required this.dayCell,
  });

  final Color surfaceColor;
  final Color headerColor;
  final TextStyle headerTextStyle;
  final TextStyle dayStyle;
  final Color selectedDayColor;
  final Color selectedDayTextColor;
  final Color todayBorderColor;
  final Color dividerColor;
  final BorderRadius borderRadius;
  final CalendarDayStyleSpec dayCell;
}

/// Figma `Controls / Date Pickers` (`40:7644`) token resolver.
abstract final class DatePickerTokens {
  DatePickerTokens._();

  static const double borderRadius = 16;
  static const double dayCellSize = 40;

  static CalendarDayStyleSpec dayCell({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    final dark = colors.palettes.dark;
    final isDark = brightness == Brightness.dark;

    return CalendarDayStyleSpec(
      size: responsiveDimension(dayCellSize),
      borderRadius: BorderRadius.circular(responsiveDimension(dayCellSize / 2)),
      defaultBackgroundColor: isDark ? dark.shade950 : colors.white,
      activeBackgroundColor: colors.primary,
      defaultTextColor: isDark ? colors.white : colors.black,
      activeTextColor: colors.white,
      textStyle: typography.smallNormal.copyWith(
        height: 1,
      ),
    );
  }

  static DatePickerStyleSpec resolve({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    final dark = colors.palettes.dark;
    final isDark = brightness == Brightness.dark;

    return DatePickerStyleSpec(
      surfaceColor: isDark ? dark.shade900 : colors.white,
      headerColor: colors.primary,
      headerTextStyle: typography.title3.copyWith(
        fontWeight: FontWeight.w700,
        color: colors.white,
      ),
      dayStyle: typography.regularNormal.copyWith(
        color: colors.textPrimary,
      ),
      selectedDayColor: colors.primary,
      selectedDayTextColor: colors.white,
      todayBorderColor: colors.primary,
      dividerColor: isDark ? dark.shade800 : dark.shade100,
      borderRadius: BorderRadius.circular(responsiveDimension(borderRadius)),
      dayCell: dayCell(
        colors: colors,
        typography: typography,
        brightness: brightness,
      ),
    );
  }

  static DatePickerThemeData datePickerTheme({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    final spec = resolve(
      colors: colors,
      typography: typography,
      brightness: brightness,
    );

    return DatePickerThemeData(
      backgroundColor: spec.surfaceColor,
      headerBackgroundColor: spec.headerColor,
      headerForegroundColor: spec.selectedDayTextColor,
      headerHeadlineStyle: spec.headerTextStyle,
      dayStyle: spec.dayStyle,
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return spec.selectedDayTextColor;
        }
        return colors.textPrimary;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return spec.selectedDayColor;
        }
        return Colors.transparent;
      }),
      todayBorder: BorderSide(color: spec.todayBorderColor),
      dividerColor: spec.dividerColor,
      shape: RoundedRectangleBorder(borderRadius: spec.borderRadius),
    );
  }
}
