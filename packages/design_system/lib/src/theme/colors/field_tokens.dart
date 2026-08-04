import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma `Controls / Text Fields` (`6:458`) + label/caption wrapper (`6:257`).
abstract final class FieldTokens {
  FieldTokens._();

  // ── Figma dimensions (`6:257`) ───────────────────────────────────────────
  static const double fieldHeight = 48;
  static const double labelGap = 12;
  static const double captionGap = 12;
  static const double horizontalPadding = 16;
  static const double verticalPadding = 16;
  static const double trailingPadding = 12;
  static const double borderRadius = 8;
  static const double borderWidthDefault = 1;
  static const double borderWidthEmphasis = 2;

  // ── Figma light-mode field colors ──────────────────────────────────────────
  static const Color _lightBorderDefault = Color(0xFFE3E5E5);
  static const Color _lightBackgroundDisabled = Color(0xFFF2F4F5);
  static const Color _lightTextDisabled = Color(0xFFCDCFD0);
  static const Color _lightBorderError = Color(0xFFFF5247);
  static const Color _lightLabel = Color(0xFF090A0A);

  static Color focusBorder(AppColors colors) => colors.fieldFocus;

  static Color errorBorder(AppColors colors, Brightness brightness) {
    return brightness == Brightness.dark ? colors.error : _lightBorderError;
  }

  static Color background(
    AppColors colors,
    Brightness brightness, {
    required bool enabled,
  }) {
    if (!enabled) {
      return brightness == Brightness.dark
          ? colors.controlFill
          : _lightBackgroundDisabled;
    }
    return brightness == Brightness.dark ? colors.surface : colors.surface;
  }

  static Color borderDefault(AppColors colors, Brightness brightness) {
    return brightness == Brightness.dark ? colors.border : _lightBorderDefault;
  }

  static Color disabledBorder(
    AppColors colors,
    Brightness brightness,
  ) {
    return background(colors, brightness, enabled: false);
  }

  static Color labelColor(AppColors colors, Brightness brightness) {
    return brightness == Brightness.dark ? colors.textPrimary : _lightLabel;
  }

  static Color hintColor(
    AppColors colors,
    Brightness brightness, {
    required bool enabled,
  }) {
    if (!enabled) {
      return brightness == Brightness.dark
          ? colors.textDisabled
          : _lightTextDisabled;
    }
    return colors.textMuted;
  }

  static Color valueColor(
    AppColors colors,
    Brightness brightness, {
    required bool enabled,
  }) {
    if (!enabled) {
      return brightness == Brightness.dark
          ? colors.textDisabled
          : _lightTextDisabled;
    }
    return brightness == Brightness.dark ? colors.textPrimary : _lightLabel;
  }

  static Color captionColor(AppColors colors, Brightness brightness) {
    return colors.textMuted;
  }

  static TextStyle labelStyle(
    AppTypography typography,
    AppColors colors,
    Brightness brightness,
  ) {
    return typography.regularNormal.copyWith(
      fontWeight: FontWeight.w500,
      height: 16 / 16,
      letterSpacing: 0,
      color: labelColor(colors, brightness),
    );
  }

  static TextStyle valueStyle(
    AppTypography typography,
    AppColors colors,
    Brightness brightness, {
    required bool enabled,
  }) {
    return typography.regularNormal.copyWith(
      height: 16 / 16,
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
    return typography.smallNormal.copyWith(
      height: 16 / 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: hintColor(colors, brightness, enabled: enabled),
    );
  }

  static TextStyle errorStyle(
    AppTypography typography,
    AppColors colors,
    Brightness brightness,
  ) {
    return typography.smallNormal.copyWith(
      height: 20 / 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: errorBorder(colors, brightness),
    );
  }

  static TextStyle captionStyle(
    AppTypography typography,
    AppColors colors,
    Brightness brightness,
  ) {
    return typography.smallNormal.copyWith(
      height: 20 / 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: captionColor(colors, brightness),
    );
  }

  static EdgeInsets contentPadding({
    bool hasPrefixIcon = false,
    bool hasTrailing = false,
  }) {
    if (hasTrailing) {
      final padding = responsiveDimension(trailingPadding);
      return EdgeInsets.fromLTRB(padding, padding, 0, padding);
    }

    return EdgeInsets.fromLTRB(
      hasPrefixIcon
          ? AppSpacing.sm + AppDimension.iconMenu + AppSpacing.sm
          : responsiveDimension(horizontalPadding),
      responsiveDimension(verticalPadding),
      responsiveDimension(horizontalPadding),
      responsiveDimension(verticalPadding),
    );
  }

  static BoxConstraints prefixIconConstraints() => BoxConstraints(
    minWidth: AppSpacing.sm + AppDimension.iconMenu + AppSpacing.sm,
    minHeight: responsiveDimension(fieldHeight),
  );

  static BoxConstraints suffixIconConstraints() => BoxConstraints(
    minWidth: AppSpacing.sm + AppDimension.iconMenu + AppSpacing.sm,
    minHeight: responsiveDimension(fieldHeight),
  );

  static BoxConstraints trailingSuffixConstraints() => BoxConstraints(
    minHeight: responsiveDimension(fieldHeight),
    maxHeight: responsiveDimension(fieldHeight),
  );

  static BorderRadius borderRadiusAll() =>
      BorderRadius.circular(responsiveDimension(borderRadius));

  static OutlineInputBorder outlineBorder(
    Color color,
    double width,
  ) {
    return OutlineInputBorder(
      borderRadius: borderRadiusAll(),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static InputDecorationTheme inputDecorationTheme({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    final defaultBorder = borderDefault(colors, brightness);
    final disabledBorderColor = disabledBorder(colors, brightness);
    final emphasisWidth = responsiveDimension(borderWidthEmphasis);
    final defaultWidth = responsiveDimension(borderWidthDefault);

    return InputDecorationTheme(
      filled: true,
      fillColor: background(colors, brightness, enabled: true),
      isDense: true,
      contentPadding: contentPadding(),
      constraints: BoxConstraints(
        minHeight: responsiveDimension(fieldHeight),
        maxHeight: responsiveDimension(fieldHeight),
      ),
      labelStyle: labelStyle(typography, colors, brightness),
      hintStyle: hintStyle(typography, colors, brightness, enabled: true),
      errorStyle: errorStyle(typography, colors, brightness),
      helperStyle: captionStyle(typography, colors, brightness),
      border: outlineBorder(defaultBorder, defaultWidth),
      enabledBorder: outlineBorder(defaultBorder, defaultWidth),
      focusedBorder: outlineBorder(focusBorder(colors), emphasisWidth),
      disabledBorder: outlineBorder(disabledBorderColor, defaultWidth),
      errorBorder: outlineBorder(
        errorBorder(colors, brightness),
        emphasisWidth,
      ),
      focusedErrorBorder: outlineBorder(
        errorBorder(colors, brightness),
        emphasisWidth,
      ),
    );
  }
}
