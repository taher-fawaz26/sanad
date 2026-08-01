import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/colors/palettes/main_palette.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:design_system/src/utils/constants/app_durations.dart';
import 'package:flutter/material.dart';

/// Design tokens for [AppBottomNavBar] mapped to `curved_navigation_bar_pro`.
///
/// Figma reference: `Nab-Bar` (`3148:27106`)
abstract final class BottomNavTokens {
  BottomNavTokens._();

  /// Bottom bar background color.
  static Color backgroundColor(AppColors colors, Brightness brightness) =>
      brightness == Brightness.dark ? colors.background : colors.surface;

  /// Animation duration for notch / bubble transitions.
  static int durationInMilliSeconds = AppDurations.notchBar.inMilliseconds;

  /// Bar height (excluding FAB protrusion).
  static const double bottomBarHeight = 72;

  /// Top corner radius of the bar.
  static const double kBottomRadius = 28;

  /// Horizontal inset for side items when corners are rounded.
  static const double contentPadding = 12;

  /// Shadow elevation.
  static const double elevation = 8;

  /// Drop shadow tint.
  static const Color shadowColor = Color(0x2B05796B);

  /// Gap between FAB edge and notch arc.
  static const double circleMargin = 8;

  /// How far the FAB centre sits below the bar top edge.
  static const double fabSink = 20;

  /// Shoulder fillet radius where the notch meets the flat bar.
  static const double notchShoulderRadius = 12;

  /// Side icon size.
  static const double kIconSize = 24;

  /// Whether labels are shown under icons.
  static const bool showLabel = true;

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

  static Color selectedIconColor(AppColors colors) => colors.primary;

  static Color unselectedIconColor(AppColors colors, Brightness brightness) =>
      brightness == Brightness.dark
          ? colors.slate400
          : const Color(0xFF828A89);

  static Color disabledIconColor(AppColors colors) => colors.textDisabled;

  /// Center FAB diameter.
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

  /// Animation curve for icon/label transitions.
  static const Curve animationCurve = Curves.easeOutCubic;
}
