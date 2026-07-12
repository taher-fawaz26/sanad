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
    // Figma status badge Success — Green/Lightest + Green/Darkest (`40:10689`).
    successContainer: Color(0xFFECFCE5),
    onSuccessContainer: Color(0xFF198155),
    error: RedPalette.shade600,
    onError: AppPalettes.whiteValue,
    // Figma status badge Alert — Red/Lightest + Red/Darkest (`40:10689`).
    errorContainer: RedPalette.shade100,
    onErrorContainer: Color(0xFFD3180C),
    warning: YellowPalette.shade500,
    onWarning: AppPalettes.whiteValue,
    // Figma status badge Warning — Yellow/Lightest + Yellow/Darkest (`40:10689`).
    warningContainer: Color(0xFFFFEFD7),
    onWarningContainer: Color(0xFFA05E03),
    info: SkyPalette.shade600,
    onInfo: AppPalettes.whiteValue,
    // Figma status badge Info — Blue/Lightest + Blue/Darkest (`40:10689`).
    infoContainer: Color(0xFFC9F0FF),
    onInfoContainer: Color(0xFF0065D0),

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
