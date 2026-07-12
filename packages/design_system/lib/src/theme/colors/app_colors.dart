import 'package:design_system/src/theme/colors/app_palettes.dart';
import 'package:flutter/material.dart';

/// **Semantic color contract for the Sanad design system.**
///
/// Widgets read colors through `context.appColors` — never raw hex values.
///
/// ### Architecture
/// - **[AppPalettes]** — six Figma ramps (`main`, `accent`, `yellow`, `dark`,
///   `sky`, `red`) plus `white` / `black`.
/// - **Semantic tokens** — UI roles (`primary`, `error`, `surface`, …) mapped
///   from palette steps in `LightColors` / `DarkColors` (theme-internal;
///   never imported outside this package).
///
/// Prefer semantic tokens in feature UI. Reach for [palettes] only when a
/// component spec names a specific ramp step.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.palettes,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.tertiary,
    required this.onTertiary,
    required this.background,
    required this.onBackground,
    required this.surface,
    required this.onSurface,
    required this.surfaceVariant,
    required this.onSurfaceVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.textInverse,
    required this.link,
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.border,
    required this.borderFocused,
    required this.fieldFocus,
    required this.divider,
    required this.disabled,
    required this.onDisabled,
    required this.controlFill,
    required this.selectedContainer,
    required this.onSelectedContainer,
  });

  /// Raw Figma palette ramps — source of truth for all color values.
  final AppPalettes palettes;

  // ── Brand ──────────────────────────────────────────────────────────────────
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color tertiary;
  final Color onTertiary;

  // ── Backgrounds ────────────────────────────────────────────────────────────
  final Color background;
  final Color onBackground;
  final Color surface;
  final Color onSurface;
  final Color surfaceVariant;
  final Color onSurfaceVariant;

  // ── Text ───────────────────────────────────────────────────────────────────
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDisabled;
  final Color textInverse;
  final Color link;

  // ── States ─────────────────────────────────────────────────────────────────
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color onInfoContainer;

  // ── Borders & Dividers ─────────────────────────────────────────────────────
  final Color border;
  final Color borderFocused;

  /// Figma field focus ring — `Success` `#06B250` (`6:257`).
  final Color fieldFocus;
  final Color divider;

  // ── Disabled ───────────────────────────────────────────────────────────────
  final Color disabled;
  final Color onDisabled;

  // ── Controls ───────────────────────────────────────────────────────────────
  /// Subtle fill for search bars, segmented tracks, and unselected chips.
  final Color controlFill;

  /// Selected chip / filter pill surface.
  final Color selectedContainer;
  final Color onSelectedContainer;

  // ── Palette shortcuts (migration — prefer [palettes] or semantic tokens) ──

  Color get white => palettes.white;
  Color get black => palettes.black;

  Color get primary50 => palettes.main.shade50;
  Color get primary300 => palettes.main.shade600;
  Color get primary400 => palettes.main.shade400;
  Color get primary500 => palettes.main.shade500;

  Color get secondary200 => palettes.accent.shade200;
  Color get secondary300 => palettes.accent.shade300;
  Color get secondary400 => palettes.accent.shade400;
  Color get secondary500 => palettes.accent.shade500;

  Color get gray50 => palettes.dark.shade50;
  Color get gray100 => palettes.dark.shade100;
  Color get gray200 => palettes.dark.shade200;
  Color get gray300 => palettes.dark.shade300;
  Color get gray400 => palettes.dark.shade400;
  Color get gray500 => palettes.dark.shade500;
  Color get gray600 => palettes.dark.shade600;
  Color get gray700 => palettes.dark.shade700;
  Color get gray800 => palettes.dark.shade800;
  Color get gray900 => palettes.dark.shade900;

  Color get slate50 => palettes.sky.shade50;
  Color get slate100 => palettes.sky.shade100;
  Color get slate200 => palettes.sky.shade200;
  Color get slate400 => palettes.sky.shade400;
  Color get slate500 => palettes.sky.shade500;
  Color get slate600 => palettes.sky.shade600;
  Color get slate950 => palettes.sky.shade950;

  Color get paymentBankCardFill => palettes.main.shade50;
  Color get paymentBankCardBorder => palettes.main.shade200;
  Color get paymentBankLeadingIconFill => palettes.red.shade100;

  Color get success50 => palettes.main.shade50;
  Color get success100 => palettes.main.shade100;
  Color get success400 => palettes.main.shade400;
  Color get success500 => palettes.main.shade500;

  Color get error50 => palettes.red.shade50;
  Color get error100 => palettes.red.shade100;
  Color get error400 => palettes.red.shade400;
  Color get error500 => palettes.red.shade600;

  Color get warning50 => palettes.yellow.shade50;
  Color get warning200 => palettes.yellow.shade200;
  Color get warning300 => palettes.yellow.shade300;
  Color get warning500 => palettes.yellow.shade500;

  Color get info100 => palettes.sky.shade100;
  Color get info400 => palettes.sky.shade400;
  Color get info500 => palettes.sky.shade500;

  @override
  AppColors copyWith({
    AppPalettes? palettes,
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? onSecondary,
    Color? tertiary,
    Color? onTertiary,
    Color? background,
    Color? onBackground,
    Color? surface,
    Color? onSurface,
    Color? surfaceVariant,
    Color? onSurfaceVariant,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textDisabled,
    Color? textInverse,
    Color? link,
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? error,
    Color? onError,
    Color? errorContainer,
    Color? onErrorContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? border,
    Color? borderFocused,
    Color? fieldFocus,
    Color? divider,
    Color? disabled,
    Color? onDisabled,
    Color? controlFill,
    Color? selectedContainer,
    Color? onSelectedContainer,
  }) {
    return AppColors(
      palettes: palettes ?? this.palettes,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      tertiary: tertiary ?? this.tertiary,
      onTertiary: onTertiary ?? this.onTertiary,
      background: background ?? this.background,
      onBackground: onBackground ?? this.onBackground,
      surface: surface ?? this.surface,
      onSurface: onSurface ?? this.onSurface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textDisabled: textDisabled ?? this.textDisabled,
      textInverse: textInverse ?? this.textInverse,
      link: link ?? this.link,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      error: error ?? this.error,
      onError: onError ?? this.onError,
      errorContainer: errorContainer ?? this.errorContainer,
      onErrorContainer: onErrorContainer ?? this.onErrorContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      border: border ?? this.border,
      borderFocused: borderFocused ?? this.borderFocused,
      fieldFocus: fieldFocus ?? this.fieldFocus,
      divider: divider ?? this.divider,
      disabled: disabled ?? this.disabled,
      onDisabled: onDisabled ?? this.onDisabled,
      controlFill: controlFill ?? this.controlFill,
      selectedContainer: selectedContainer ?? this.selectedContainer,
      onSelectedContainer: onSelectedContainer ?? this.onSelectedContainer,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      palettes: palettes.lerp(other.palettes, t),
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      onTertiary: Color.lerp(onTertiary, other.onTertiary, t)!,
      background: Color.lerp(background, other.background, t)!,
      onBackground: Color.lerp(onBackground, other.onBackground, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      onSurfaceVariant: Color.lerp(
        onSurfaceVariant,
        other.onSurfaceVariant,
        t,
      )!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      link: Color.lerp(link, other.link, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer:
          Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      error: Color.lerp(error, other.error, t)!,
      onError: Color.lerp(onError, other.onError, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      onErrorContainer: Color.lerp(
        onErrorContainer,
        other.onErrorContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer:
          Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderFocused: Color.lerp(borderFocused, other.borderFocused, t)!,
      fieldFocus: Color.lerp(fieldFocus, other.fieldFocus, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
      onDisabled: Color.lerp(onDisabled, other.onDisabled, t)!,
      controlFill: Color.lerp(controlFill, other.controlFill, t)!,
      selectedContainer: Color.lerp(
        selectedContainer,
        other.selectedContainer,
        t,
      )!,
      onSelectedContainer: Color.lerp(
        onSelectedContainer,
        other.onSelectedContainer,
        t,
      )!,
    );
  }
}

/// Convenience accessor — use in build methods instead of
/// `Theme.of(context).extension<AppColors>()!`
extension AppColorsX on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
