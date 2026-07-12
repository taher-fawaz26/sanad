import 'package:design_system/design_system.dart' show AppSnackbar, AppTheme;
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma snackbar color variant (`97:3434`).
enum AppSnackbarColor {
  dark,
  primary,

  /// Figma error snackbar (`322:9721`) — red/500 background.
  error,
}

/// Figma snackbar layout (`97:3434`).
enum AppSnackbarLayout {
  box,
  fullWidth,
}

/// Figma snackbar action slot (`97:3434`).
enum AppSnackbarAction {
  none,
  text,
  icon,
}

/// Resolved styling for [AppSnackbar].
@immutable
class SnackbarStyleSpec {
  const SnackbarStyleSpec({
    required this.backgroundColor,
    required this.borderRadius,
    required this.horizontalPadding,
    required this.verticalPaddingCompact,
    required this.verticalPaddingExpanded,
    required this.contentGap,
    required this.textGap,
    required this.iconSize,
    required this.titleStyle,
    required this.captionStyle,
    required this.actionStyle,
    required this.boxMaxWidth,
  });

  final Color backgroundColor;
  final BorderRadius borderRadius;
  final double horizontalPadding;
  final double verticalPaddingCompact;
  final double verticalPaddingExpanded;
  final double contentGap;
  final double textGap;
  final double iconSize;
  final TextStyle titleStyle;
  final TextStyle captionStyle;
  final TextStyle actionStyle;
  final double boxMaxWidth;

  EdgeInsets padding({required bool hasCaption}) {
    final vertical =
        hasCaption ? verticalPaddingExpanded : verticalPaddingCompact;
    return EdgeInsets.symmetric(
      horizontal: horizontalPadding,
      vertical: vertical,
    );
  }
}

/// Theme extension registered in [AppTheme] for Figma snackbars.
@immutable
class AppSnackbarTheme extends ThemeExtension<AppSnackbarTheme> {
  const AppSnackbarTheme({
    required this.dark,
    required this.primary,
    required this.error,
  });

  final SnackbarStyleSpec dark;
  final SnackbarStyleSpec primary;
  final SnackbarStyleSpec error;

  SnackbarStyleSpec specFor(AppSnackbarColor color) => switch (color) {
        AppSnackbarColor.dark => dark,
        AppSnackbarColor.primary => primary,
        AppSnackbarColor.error => error,
      };

  @override
  AppSnackbarTheme copyWith({
    SnackbarStyleSpec? dark,
    SnackbarStyleSpec? primary,
    SnackbarStyleSpec? error,
  }) {
    return AppSnackbarTheme(
      dark: dark ?? this.dark,
      primary: primary ?? this.primary,
      error: error ?? this.error,
    );
  }

  @override
  AppSnackbarTheme lerp(covariant AppSnackbarTheme? other, double t) {
    if (other == null) {
      return this;
    }
    return t < 0.5 ? this : other;
  }
}

extension AppSnackbarThemeX on BuildContext {
  AppSnackbarTheme get appSnackbarTheme =>
      Theme.of(this).extension<AppSnackbarTheme>()!;
}

/// Figma `Views / Snackbars` (`97:3434`) token resolver.
abstract final class SnackbarTokens {
  SnackbarTokens._();

  static const double borderRadius = 8;
  static const double horizontalPadding = 16;
  static const double verticalPaddingCompact = 14;
  static const double verticalPaddingExpanded = 12;
  static const double contentGap = 16;
  static const double textGap = 4;
  static const double iconSize = 24;
  static const double boxMaxWidth = 327;

  static AppSnackbarTheme themeExtension({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    return AppSnackbarTheme(
      dark: _resolve(
        color: AppSnackbarColor.dark,
        colors: colors,
        typography: typography,
        brightness: brightness,
      ),
      primary: _resolve(
        color: AppSnackbarColor.primary,
        colors: colors,
        typography: typography,
        brightness: brightness,
      ),
      error: _resolve(
        color: AppSnackbarColor.error,
        colors: colors,
        typography: typography,
        brightness: brightness,
      ),
    );
  }

  static SnackbarStyleSpec resolve({
    required AppSnackbarColor color,
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    return _resolve(
      color: color,
      colors: colors,
      typography: typography,
      brightness: brightness,
    );
  }

  static SnackbarStyleSpec _resolve({
    required AppSnackbarColor color,
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    final main = colors.palettes.main;
    final dark = colors.palettes.dark;
    final red = colors.palettes.red;
    final sky = colors.palettes.sky;
    final isPrimary = color == AppSnackbarColor.primary;
    final isError = color == AppSnackbarColor.error;

    return SnackbarStyleSpec(
      backgroundColor: switch (color) {
        AppSnackbarColor.primary => main.shade700,
        AppSnackbarColor.error => red.shade500,
        AppSnackbarColor.dark => dark.shade950,
      },
      borderRadius: BorderRadius.circular(responsiveDimension(borderRadius)),
      horizontalPadding: responsiveDimension(horizontalPadding),
      verticalPaddingCompact: responsiveDimension(verticalPaddingCompact),
      verticalPaddingExpanded: responsiveDimension(verticalPaddingExpanded),
      contentGap: responsiveDimension(contentGap),
      textGap: responsiveDimension(textGap),
      iconSize: responsiveDimension(iconSize),
      titleStyle: typography.regularNormal.copyWith(
        color: colors.white,
        height: 20 / 16,
      ),
      captionStyle: typography.smallNormal.copyWith(
        color: isError
            ? sky.shade50
            : (isPrimary ? main.shade200 : dark.shade400),
        height: 16 / 14,
      ),
      actionStyle: typography.regularNormal.copyWith(
        color: isPrimary ? colors.white : main.shade300,
        height: 20 / 16,
      ),
      boxMaxWidth: responsiveDimension(boxMaxWidth),
    );
  }
}
