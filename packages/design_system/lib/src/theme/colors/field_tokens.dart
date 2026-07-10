import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:design_system/src/theme/typography/responsive_font_scale.dart';
import 'package:flutter/material.dart';

/// Figma `Controls / Text Fields` (`6:458`) + label/caption wrapper (`6:257`).
abstract final class FieldTokens {
  FieldTokens._();

  static Color focusBorder(AppColors colors) => colors.fieldFocus;

  static Color errorBorder(AppColors colors) => colors.error;

  static Color background(
    AppColors colors,
    Brightness brightness, {
    required bool enabled,
  }) {
    if (!enabled) {
      return brightness == Brightness.dark
          ? colors.controlFill
          : colors.disabled;
    }
    return brightness == Brightness.dark ? colors.background : colors.surface;
  }

  static Color borderDefault(AppColors colors, Brightness brightness) {
    return brightness == Brightness.dark ? colors.border : colors.border;
  }

  static Color disabledBorder(AppColors colors, Brightness brightness) {
    return background(colors, brightness, enabled: false);
  }

  static Color labelColor(AppColors colors) => colors.textPrimary;

  static Color hintColor(
    AppColors colors,
    Brightness brightness, {
    required bool enabled,
  }) {
    if (!enabled) {
      return colors.textDisabled;
    }
    return colors.textMuted;
  }

  static Color valueColor(
    AppColors colors,
    Brightness brightness, {
    required bool enabled,
  }) {
    if (!enabled) {
      return colors.textDisabled;
    }
    return colors.textPrimary;
  }

  static Color captionColor(AppColors colors, Brightness brightness) {
    return colors.textMuted;
  }

  static TextStyle labelStyle(AppTypography typography, AppColors colors) {
    return typography.labelLarge.copyWith(
      fontSize: 16.rfs,
      height: 1,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      color: labelColor(colors),
    );
  }

  static TextStyle valueStyle(
    AppTypography typography,
    AppColors colors,
    Brightness brightness, {
    required bool enabled,
  }) {
    return typography.bodyLarge.copyWith(
      fontSize: 16.rfs,
      height: 1,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: valueColor(colors, brightness, enabled: enabled),
    );
  }

  static TextStyle hintStyle(
    AppTypography typography,
    AppColors colors,
    Brightness brightness, {
    required bool enabled,
  }) {
    return typography.bodyLarge.copyWith(
      fontSize: 16.rfs,
      height: 1,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: hintColor(colors, brightness, enabled: enabled),
    );
  }

  static TextStyle errorStyle(AppTypography typography, AppColors colors) {
    return typography.bodySmall.copyWith(
      fontSize: 14.rfs,
      height: 20 / 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: errorBorder(colors),
    );
  }

  static TextStyle captionStyle(
    AppTypography typography,
    AppColors colors,
    Brightness brightness,
  ) {
    return typography.bodySmall.copyWith(
      fontSize: 14.rfs,
      height: 20 / 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: captionColor(colors, brightness),
    );
  }

  static EdgeInsets contentPadding({bool hasPrefixIcon = false}) {
    return EdgeInsets.symmetric(
      horizontal: hasPrefixIcon
          ? AppSpacing.sm + AppDimension.iconMenu + AppSpacing.sm
          : AppSpacing.lg,
      vertical: AppSpacing.sm,
    );
  }

  static BoxConstraints prefixIconConstraints() => BoxConstraints(
        minWidth: AppSpacing.sm + AppDimension.iconMenu + AppSpacing.sm,
        minHeight: AppDimension.fieldHeightLg,
      );

  static BoxConstraints suffixIconConstraints() => BoxConstraints(
        minWidth: AppSpacing.sm + AppDimension.iconMenu + AppSpacing.sm,
        minHeight: AppDimension.fieldHeightLg,
      );

  static BorderRadius borderRadiusAll() =>
      BorderRadius.circular(AppDimension.radiusSm);

  static InputDecorationTheme inputDecorationTheme({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    final radius = borderRadiusAll();
    final defaultBorderWidth = AppDimension.borderHairline;
    final emphasisBorderWidth = AppDimension.borderHairline * 2;

    OutlineInputBorder outlineBorder(Color color, double width) {
      return OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: color, width: width),
      );
    }

    final defaultBorder = borderDefault(colors, brightness);
    final disabledBorderColor = disabledBorder(colors, brightness);

    return InputDecorationTheme(
      filled: true,
      fillColor: background(colors, brightness, enabled: true),
      isDense: true,
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      labelStyle: labelStyle(typography, colors),
      hintStyle: hintStyle(typography, colors, brightness, enabled: true),
      errorStyle: errorStyle(typography, colors),
      helperStyle: captionStyle(typography, colors, brightness),
      border: outlineBorder(defaultBorder, defaultBorderWidth),
      enabledBorder: outlineBorder(defaultBorder, defaultBorderWidth),
      focusedBorder: outlineBorder(
        focusBorder(colors),
        emphasisBorderWidth,
      ),
      disabledBorder: outlineBorder(
        disabledBorderColor,
        defaultBorderWidth,
      ),
      errorBorder: outlineBorder(errorBorder(colors), emphasisBorderWidth),
      focusedErrorBorder: outlineBorder(
        errorBorder(colors),
        emphasisBorderWidth,
      ),
    );
  }
}
