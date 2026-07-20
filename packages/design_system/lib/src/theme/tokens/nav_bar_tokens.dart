import 'package:design_system/design_system.dart'
    show AppLargeNavBar, AppNavBar, AppTheme;
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma nav bar trailing action (`40:6839`, `40:6931`).
enum AppNavBarTrailingAction {
  none,
  icon,
  text,
  button,
}

/// Resolved styling for [AppNavBar].
@immutable
class StandardNavBarStyleSpec {
  const StandardNavBarStyleSpec({
    required this.height,
    required this.heightWithButton,
    required this.horizontalPadding,
    required this.backgroundColor,
    required this.titleStyle,
    required this.actionTextStyle,
    required this.iconSize,
    required this.leadingIconTextGap,
    required this.actionButtonPadding,
    required this.actionButtonRadius,
    required this.actionButtonTextStyle,
  });

  final double height;
  final double heightWithButton;
  final double horizontalPadding;
  final Color backgroundColor;
  final TextStyle titleStyle;
  final TextStyle actionTextStyle;
  final double iconSize;
  final double leadingIconTextGap;
  final EdgeInsets actionButtonPadding;
  final BorderRadius actionButtonRadius;
  final TextStyle actionButtonTextStyle;
}

/// Resolved styling for [AppLargeNavBar].
@immutable
class LargeNavBarStyleSpec {
  const LargeNavBarStyleSpec({
    required this.heightCompact,
    required this.heightExpanded,
    required this.horizontalPadding,
    required this.backgroundColor,
    required this.titleStyle,
    required this.titleStyleLarge,
    required this.captionStyle,
    required this.iconSize,
    required this.leadingIconTextGap,
    required this.trailingIconInset,
    required this.trailingButtonInset,
    required this.titleRightInsetIcon,
    required this.titleRightInsetButton,
    required this.actionButtonPadding,
    required this.actionButtonRadius,
    required this.actionButtonTextStyle,
  });

  final double heightCompact;
  final double heightExpanded;
  final double horizontalPadding;
  final Color backgroundColor;
  final TextStyle titleStyle;
  final TextStyle titleStyleLarge;
  final TextStyle captionStyle;
  final double iconSize;
  final double leadingIconTextGap;
  final double trailingIconInset;
  final double trailingButtonInset;
  final double titleRightInsetIcon;
  final double titleRightInsetButton;
  final EdgeInsets actionButtonPadding;
  final BorderRadius actionButtonRadius;
  final TextStyle actionButtonTextStyle;
}

/// Theme extension registered in [AppTheme] for Figma nav bars.
@immutable
class AppNavBarTheme extends ThemeExtension<AppNavBarTheme> {
  const AppNavBarTheme({
    required this.standard,
    required this.large,
  });

  final StandardNavBarStyleSpec standard;
  final LargeNavBarStyleSpec large;

  @override
  AppNavBarTheme copyWith({
    StandardNavBarStyleSpec? standard,
    LargeNavBarStyleSpec? large,
  }) {
    return AppNavBarTheme(
      standard: standard ?? this.standard,
      large: large ?? this.large,
    );
  }

  @override
  AppNavBarTheme lerp(covariant AppNavBarTheme? other, double t) {
    if (other == null) {
      return this;
    }
    return t < 0.5 ? this : other;
  }
}

extension AppNavBarThemeX on BuildContext {
  AppNavBarTheme get appNavBarTheme =>
      Theme.of(this).extension<AppNavBarTheme>()!;
}

/// Figma `Bars / Nav Bars` (`40:6839`, `40:6931`) token resolver.
abstract final class NavBarTokens {
  NavBarTokens._();

  static const double standardHeight = 48;
  static const double standardHeightWithButton = 48;
  static const double standardHorizontalPadding = 20;
  static const double largeHeightCompact = 60;
  static const double largeHeightExpanded = 92;
  static const double largeHorizontalPadding = 24;
  static const double iconSize = 24;
  static const double leadingIconTextGap = 4;
  static const double titleSize = 18;
  static const double largeTitleSize = 24;
  static const double largeTitleSizeBold = 32;
  static const double captionSize = 16;

  static AppNavBarTheme themeExtension({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    return AppNavBarTheme(
      standard: standard(
        colors: colors,
        typography: typography,
        brightness: brightness,
      ),
      large: large(
        colors: colors,
        typography: typography,
        brightness: brightness,
      ),
    );
  }

  static StandardNavBarStyleSpec standard({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    final dark = colors.palettes.dark;

    return StandardNavBarStyleSpec(
      height: responsiveDimension(standardHeight),
      heightWithButton: responsiveDimension(standardHeightWithButton),
      horizontalPadding: responsiveDimension(standardHorizontalPadding),
      backgroundColor: isDark ? dark.shade950 : colors.white,
      titleStyle: typography.regularNormal.copyWith(
        fontSize: responsiveDimension(titleSize),
        height: 1,
        color: isDark ? colors.white : dark.shade950,
      ),
      actionTextStyle: typography.regularNormal.copyWith(
        fontSize: responsiveDimension(titleSize),
        fontWeight: FontWeight.w500,
        height: 1,
        color: colors.primary,
      ),
      iconSize: responsiveDimension(iconSize),
      leadingIconTextGap: responsiveDimension(leadingIconTextGap),
      actionButtonPadding: EdgeInsets.symmetric(
        horizontal: responsiveDimension(16),
        vertical: responsiveDimension(8),
      ),
      actionButtonRadius: BorderRadius.circular(responsiveDimension(48)),
      actionButtonTextStyle: typography.regularNormal.copyWith(
        fontWeight: FontWeight.w500,
        height: 1,
        color: colors.white,
      ),
    );
  }

  static LargeNavBarStyleSpec large({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    final dark = colors.palettes.dark;
    final foreground = isDark ? colors.white : dark.shade950;

    return LargeNavBarStyleSpec(
      heightCompact: responsiveDimension(largeHeightCompact),
      heightExpanded: responsiveDimension(largeHeightExpanded),
      horizontalPadding: responsiveDimension(largeHorizontalPadding),
      backgroundColor: isDark ? dark.shade950 : colors.white,
      titleStyle: typography.title2.copyWith(
        fontWeight: FontWeight.w600,
        color: foreground,
        height: 36 / 24,
      ),
      titleStyleLarge: typography.title1.copyWith(
        fontWeight: FontWeight.w700,
        color: foreground,
        height: 36 / 32,
      ),
      captionStyle: typography.regularNormal.copyWith(
        color: foreground,
        height: 24 / 16,
      ),
      iconSize: responsiveDimension(iconSize),
      leadingIconTextGap: responsiveDimension(leadingIconTextGap),
      trailingIconInset: responsiveDimension(32),
      trailingButtonInset: responsiveDimension(24),
      titleRightInsetIcon: responsiveDimension(56),
      titleRightInsetButton: responsiveDimension(107),
      actionButtonPadding: EdgeInsets.symmetric(
        horizontal: responsiveDimension(16),
        vertical: responsiveDimension(8),
      ),
      actionButtonRadius: BorderRadius.circular(responsiveDimension(48)),
      actionButtonTextStyle: typography.regularNormal.copyWith(
        fontWeight: FontWeight.w500,
        height: 1,
        color: colors.white,
      ),
    );
  }

  static AppBarTheme appBarTheme({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    final spec = standard(
      colors: colors,
      typography: typography,
      brightness: brightness,
    );

    return AppBarTheme(
      backgroundColor: spec.backgroundColor,
      foregroundColor: spec.titleStyle.color,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: spec.titleStyle,
      iconTheme: IconThemeData(
        color: colors.primary,
        size: spec.iconSize,
      ),
      actionsIconTheme: IconThemeData(
        color: colors.primary,
        size: spec.iconSize,
      ),
    );
  }
}
