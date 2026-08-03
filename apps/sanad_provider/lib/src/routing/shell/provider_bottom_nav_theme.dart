import 'package:bottom_nav_bar/bottom_nav_bar.dart';

import 'package:design_system/design_system.dart';

import 'package:flutter/material.dart';

/// Maps Sanad design tokens to [BottomNavThemeData] for provider shell navigation.

///

/// Notch/FAB metrics align with Figma `Nab-Bar` via [BottomNavTokens] in

/// `packages/design_system/lib/src/theme/tokens/bottom_nav_tokens.dart`.

BottomNavThemeData providerBottomNavTheme(BuildContext context) {
  final colors = context.appColors;

  final typography = context.appTypography;

  final brightness = Theme.of(context).brightness;

  final unselectedColor = brightness == Brightness.dark
      ? colors.slate400
      : const Color(0xFFA2A2A2);

  const fabSize = 52.0;

  const notchMargin = 16.0;

  final labelStyle = typography.tinyNormal.copyWith(
    fontSize: 12,

    height: 16 / 12,

    fontWeight: FontWeight.w500,
  );

  return BottomNavThemeData(
    horizontalInset: AppSpacing.lg,

    bottomInset: 0,

    barHeight: 72,

    fabSize: fabSize,

    fabSink: -5,

    contentPadding: 12,

    cornerRadius: 28,

    elevation: 8,

    shadowColor: const Color(0x2B05796B),

    barColor: colors.surface,

    selectedColor: colors.primary,

    unselectedColor: unselectedColor,

    fabBackgroundColor: colors.primary,

    fabForegroundColor: colors.white,

    fabOpenBackgroundColor: const Color(0xFFF9F9FA),

    fabOpenForegroundColor: const Color(0xFF020619),

    notchShoulderRadius: 24,

    notchMargin: notchMargin,

    fabGlowColor: colors.primary.withValues(alpha: 0.30),

    fabGlowBlur: 12,

    centerGap: fabSize + notchMargin * 2,

    labelStyle: labelStyle,

    selectedLabelStyle: labelStyle,
  );
}
