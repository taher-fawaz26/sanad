import 'package:bottom_nav_bar/bottom_nav_bar.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Maps Sanad design tokens to [BottomNavThemeData] for provider shell navigation.
BottomNavThemeData providerBottomNavTheme(BuildContext context) {
  final colors = context.appColors;
  final typography = context.appTypography;
  final brightness = Theme.of(context).brightness;
  final unselectedColor = brightness == Brightness.dark
      ? colors.slate400
      : const Color(0xFF828A89);

  final labelStyle = typography.tinyNormal.copyWith(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
  );

  return BottomNavThemeData(
    horizontalInset: AppSpacing.lg,
    bottomInset: AppSpacing.sm,
    contentPadding: AppSpacing.md,
    cornerRadius: AppRadius.lg,
    shadowColor: const Color(0x2B05796B),
    barColor: colors.surface,
    selectedColor: colors.primary,
    unselectedColor: unselectedColor,
    fabBackgroundColor: colors.primary,
    fabForegroundColor: colors.white,
    labelStyle: labelStyle,
    selectedLabelStyle: labelStyle,
  );
}
