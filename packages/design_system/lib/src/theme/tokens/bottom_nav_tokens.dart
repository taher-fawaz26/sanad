import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/colors/palettes/main_palette.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:design_system/src/utils/constants/app_durations.dart';
import 'package:flutter/material.dart';

/// Design tokens for [AppBottomNavBar] mapped to `animated_notch_bottom_bar` API.
///
/// Figma reference: `Nab-Bar` (`3148:27106`)
/// Dribbble reference: Notch bottom navigation design
abstract final class BottomNavTokens {
  BottomNavTokens._();

  // ========== Package Parameters ==========

  /// Bottom bar background color — package `color` parameter.
  static Color backgroundColor(AppColors colors, Brightness brightness) =>
      brightness == Brightness.dark ? colors.background : colors.surface;

  /// Notch background color — package `notchColor` parameter.
  static Color notchColor(AppColors colors, Brightness brightness) =>
      backgroundColor(colors, brightness);

  /// Animation duration — package `durationInMilliSeconds` parameter.
  static int durationInMilliSeconds = AppDurations.notchBar.inMilliseconds;

  /// Bar height — package `bottomBarHeight` parameter.
  static const double bottomBarHeight = 72;

  /// Notch bottom radius — package `kBottomRadius` parameter.
  static const double kBottomRadius = 28;

  /// Show bar top radius — package `showTopRadius` parameter.
  static const bool showTopRadius = true;

  /// Show bar bottom radius — package `showBottomRadius` parameter.
  static const bool showBottomRadius = true;

  /// Remove margins — package `removeMargins` parameter.
  static const bool removeMargins = true;

  /// Shadow elevation — package `elevation` and `shadowElevation` parameters.
  static const double elevation = 8;

  /// Show shadow — package `showShadow` parameter.
  static bool showShadow(Brightness brightness) =>
      brightness == Brightness.light;

  /// Show blur bottom bar — package `showBlurBottomBar` parameter.
  static const bool showBlurBottomBar = false;

  /// Blur opacity — package `blurOpacity` parameter (when blur is enabled).
  static const double blurOpacity = 0;

  /// Blur filter X — package `blurFilterX` parameter (when blur is enabled).
  static const double blurFilterX = 0;

  /// Blur filter Y — package `blurFilterY` parameter (when blur is enabled).
  static const double blurFilterY = 0;

  /// Icon size — package `kIconSize` parameter.
  static const double kIconSize = 24;

  /// Top margin — package `topMargin` parameter.
  static const double topMargin = 12;

  /// Circle margin — package `circleMargin` parameter.
  static const double circleMargin = 8;

  /// Show label — package `showLabel` parameter.
  static const bool showLabel = true;

  // ========== Item Style Tokens ==========

  /// Label text style for selected items.
  static TextStyle selectedLabelStyle(
    AppTypography typography,
    AppColors colors,
  ) =>
      typography.tinyNormal.copyWith(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
        color: colors.primary,
      );

  /// Label text style for unselected items.
  static TextStyle unselectedLabelStyle(
    AppTypography typography,
    AppColors colors,
    Brightness brightness,
  ) =>
      typography.tinyNormal.copyWith(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
        color: brightness == Brightness.dark
            ? colors.slate400
            : const Color(0xFF828A89),
      );

  /// Label text style for disabled items.
  static TextStyle disabledLabelStyle(
    AppTypography typography,
    AppColors colors,
  ) =>
      typography.tinyNormal.copyWith(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
        color: colors.textDisabled,
      );

  // ========== Icon Colors ==========

  static Color selectedIconColor(AppColors colors) => colors.primary;

  static Color unselectedIconColor(AppColors colors, Brightness brightness) =>
      brightness == Brightness.dark
          ? colors.slate400
          : const Color(0xFF828A89);

  static Color disabledIconColor(AppColors colors) => colors.textDisabled;

  // ========== Center FAB Tokens ==========

  /// Center FAB size.
  static const double centerFabSize = 52;

  /// Center FAB inactive color.
  static Color centerFabInactiveColor(AppColors colors) => colors.slate400;

  /// Center FAB active color.
  static Color centerFabActiveColor(AppColors colors, Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFF0C8A7B)
          : MainPalette.shade600;

  /// Center FAB disabled color.
  static Color centerFabDisabledColor(AppColors colors) => colors.textDisabled;

  /// Center FAB border color.
  static Color centerFabBorderColor(AppColors colors) => colors.white;

  /// Center FAB icon color.
  static Color centerFabIconColor(AppColors colors) => colors.white;

  /// Center FAB shadow.
  static const List<BoxShadow> centerFabShadow = [
    BoxShadow(
      color: Color(0x2B05796B),
      blurRadius: 19,
      offset: Offset(0, 8),
    ),
  ];

  // ========== Animation Tokens ==========

  /// Selected icon scale factor.
  static const double selectedIconScale = 1.1;

  /// Unselected icon opacity.
  static const double unselectedIconOpacity = 0.72;

  /// Animation curve for icon/label transitions.
  static const Curve animationCurve = Curves.easeOutCubic;
}
