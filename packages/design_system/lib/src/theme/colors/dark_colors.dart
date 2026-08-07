import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/colors/app_palettes.dart';
import 'package:design_system/src/theme/colors/light_colors.dart'
    show LightColors;
import 'package:design_system/src/theme/colors/palettes/accent_palette.dart';
import 'package:design_system/src/theme/colors/palettes/dark_palette.dart';
import 'package:design_system/src/theme/colors/palettes/main_palette.dart';
import 'package:design_system/src/theme/colors/palettes/red_palette.dart';
import 'package:design_system/src/theme/colors/palettes/sky_palette.dart';
import 'package:design_system/src/theme/colors/palettes/yellow_palette.dart';
import 'package:flutter/material.dart';

/// Dark mode semantic color assignments — same token names as [LightColors].
final class DarkColors {
  DarkColors._();

  static const Color _successWash = Color(0xFF0A2E24);
  static const Color _errorWash = Color(0xFF3A0A14);
  static const Color _warningWash = Color(0xFF2A1F0A);
  static const Color _infoWash = Color(0xFF131C20);

  static const AppColors colors = AppColors(
    palettes: AppPalettes.standard,

    // ── Brand ──────────────────────────────────────────────────────────────
    primary: MainPalette.shade400,
    onPrimary: MainPalette.shade950,
    secondary: AccentPalette.shade300,
    onSecondary: MainPalette.shade950,
    tertiary: MainPalette.shade300,
    onTertiary: MainPalette.shade950,

    // ── Backgrounds ─────────────────────────────────────────────────────────
    background: DarkPalette.shade950,
    onBackground: DarkPalette.shade50,
    surface: DarkPalette.shade900,
    onSurface: DarkPalette.shade50,
    surfaceVariant: DarkPalette.shade800,
    onSurfaceVariant: DarkPalette.shade200,

    // ── Text ────────────────────────────────────────────────────────────────
    textPrimary: DarkPalette.shade50,
    textSecondary: MainPalette.shade100,
    textMuted: DarkPalette.shade400,
    textDisabled: DarkPalette.shade500,
    textInverse: DarkPalette.shade900,
    link: MainPalette.shade300,

    // ── States ──────────────────────────────────────────────────────────────
    success: MainPalette.shade400,
    onSuccess: MainPalette.shade950,
    successContainer: _successWash,
    onSuccessContainer: MainPalette.shade200,
    error: RedPalette.shade400,
    onError: AppPalettes.whiteValue,
    errorContainer: _errorWash,
    onErrorContainer: RedPalette.shade200,
    warning: YellowPalette.shade400,
    onWarning: YellowPalette.shade950,
    warningContainer: _warningWash,
    onWarningContainer: YellowPalette.shade300,
    info: SkyPalette.shade400,
    onInfo: SkyPalette.shade950,
    infoContainer: _infoWash,
    onInfoContainer: SkyPalette.shade200,

    // ── Borders & Dividers ───────────────────────────────────────────────────
    border: DarkPalette.shade700,
    borderFocused: MainPalette.shade400,
    fieldFocus: Color(0xFF06B250),
    divider: DarkPalette.shade700,

    // ── Disabled ────────────────────────────────────────────────────────────
    disabled: DarkPalette.shade800,
    onDisabled: DarkPalette.shade500,

    // ── Controls ────────────────────────────────────────────────────────────
    controlFill: DarkPalette.shade900,
    selectedContainer: Color(0xFFE7E7FF),
    onSelectedContainer: Color(0xFF6B4EFF),
  );
}
