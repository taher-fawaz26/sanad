import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/colors/app_palettes.dart';
import 'package:design_system/src/theme/colors/palettes/accent_palette.dart';
import 'package:design_system/src/theme/colors/palettes/dark_palette.dart';
import 'package:design_system/src/theme/colors/palettes/main_palette.dart';
import 'package:design_system/src/theme/colors/palettes/red_palette.dart';
import 'package:design_system/src/theme/colors/palettes/sky_palette.dart';
import 'package:design_system/src/theme/colors/palettes/yellow_palette.dart';
import 'package:flutter/material.dart';

/// Light mode semantic color assignments — Figma `design-system-sanad`.
final class LightColors {
  LightColors._();

  static const AppColors colors = AppColors(
    palettes: AppPalettes.light,

    // ── Brand ──────────────────────────────────────────────────────────────
    primary: MainPalette.shade600,
    onPrimary: AppPalettes.whiteValue,
    secondary: AccentPalette.shade200,
    onSecondary: MainPalette.shade950,
    tertiary: MainPalette.shade500,
    onTertiary: AppPalettes.whiteValue,

    // ── Backgrounds ─────────────────────────────────────────────────────────
    background: DarkPalette.shade50,
    onBackground: DarkPalette.shade900,
    surface: AppPalettes.whiteValue,
    onSurface: DarkPalette.shade900,
    surfaceVariant: MainPalette.shade50,
    onSurfaceVariant: DarkPalette.shade600,

    // ── Text ────────────────────────────────────────────────────────────────
    textPrimary: DarkPalette.shade900,
    textSecondary: DarkPalette.shade600,
    textMuted: DarkPalette.shade500,
    textDisabled: DarkPalette.shade300,
    textInverse: AppPalettes.whiteValue,
    link: MainPalette.shade700,

    // ── States ──────────────────────────────────────────────────────────────
    success: MainPalette.shade500,
    onSuccess: AppPalettes.whiteValue,
    successContainer: MainPalette.shade50,
    onSuccessContainer: MainPalette.shade700,
    error: RedPalette.shade600,
    onError: AppPalettes.whiteValue,
    errorContainer: RedPalette.shade50,
    onErrorContainer: RedPalette.shade700,
    warning: YellowPalette.shade500,
    onWarning: AppPalettes.whiteValue,
    warningContainer: YellowPalette.shade50,
    onWarningContainer: YellowPalette.shade700,
    info: SkyPalette.shade600,
    onInfo: AppPalettes.whiteValue,
    infoContainer: SkyPalette.shade50,
    onInfoContainer: SkyPalette.shade700,

    // ── Borders & Dividers ───────────────────────────────────────────────────
    border: DarkPalette.shade200,
    borderFocused: MainPalette.shade600,
    fieldFocus: Color(0xFF06B250),
    divider: DarkPalette.shade200,

    // ── Disabled ────────────────────────────────────────────────────────────
    disabled: DarkPalette.shade200,
    onDisabled: DarkPalette.shade400,

    // ── Controls ────────────────────────────────────────────────────────────
    controlFill: DarkPalette.shade100,
    selectedContainer: Color(0xFFE7E7FF),
    onSelectedContainer: Color(0xFF6B4EFF),
  );
}
