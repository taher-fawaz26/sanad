import 'package:bottom_nav_bar/bottom_nav_bar.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Maps Sanad design tokens to [BottomNavThemeData] for provider shell
/// navigation.
///
/// Flat icon+label tab bar — Figma `Bars / Tab Bars: Icon & Text`
/// (`1526:12109`).
BottomNavThemeData providerBottomNavTheme(BuildContext context) {
  final colors = context.appColors;
  final typography = context.appTypography;
  final unselectedColor = colors.palettes.sky.shade600;

  final labelStyle = typography.smallNormal.copyWith(
    fontWeight: FontWeight.w500,
    height: 12 / 14,
  );

  return BottomNavThemeData(
    horizontalInset: 0,
    bottomInset: 0,
    barHeight: 56,
    // Flat bar — no center FAB notch.
    centerGap: 0,
    fabSize: 0,
    contentPadding: 0,
    cornerRadius: 12,
    elevation: 4,
    // Figma Shadow/Small — soft ambient shadow under the bar.
    shadowColor: const Color(0x14141414),
    barColor: colors.white,
    selectedColor: colors.primary,
    unselectedColor: unselectedColor,
    labelStyle: labelStyle,
    selectedLabelStyle: labelStyle,
  );
}
