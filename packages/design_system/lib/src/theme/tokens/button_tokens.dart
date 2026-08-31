import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/colors/color_scale.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma `Controls / Buttons` (`30:1738`) — visual form.
///
/// Orthogonal to [AppButtonIntent]: any variant can be combined with any
/// intent (e.g. `outline` + `destructive`, `primary` + `warning`).
enum AppButtonVariant {
  /// Figma `Type=Primary` — solid fill.
  primary,

  /// Figma `Type=Secondary` — tonal surface.
  secondary,

  /// Figma `Type=Outline` — bordered, transparent fill.
  outline,

  /// Figma `Type=Transparent` — text-only / ghost.
  transparent,
}

/// Semantic color intent for a button — orthogonal to [AppButtonVariant].
///
/// Figma itself doesn't (yet) formalise warning/destructive as a `Type=`
/// variant — they only exist today as ad-hoc fill overrides on `Type=Primary`
/// instances (e.g. the "Delete"/"Unsuspend" CTAs in `Controls / Buttons`
/// usage). This enum makes that distinction a first-class, combinable axis
/// instead of a second, narrower mechanism bolted onto the variant.
enum AppButtonIntent {
  /// Default brand color (`main` palette).
  standard,

  /// Caution CTA — yellow palette (`yallow/400` in Figma, e.g. suspend).
  warning,

  /// Destructive CTA — red palette (e.g. delete).
  destructive,

  /// Plain gray tonal fill with a near-black label — Figma `6974:25087`
  /// (client OAuth screen: Continue with Email / Google / Phone). Distinct
  /// from [standard]'s brand-tinted soft fill, which reads too green for a
  /// neutral secondary action on that screen.
  neutral,
}

/// Figma button size tier (`30:1738`).
enum AppButtonSize {
  /// Full-width block — 48 dp tall.
  block,

  /// Intrinsic-width large — 48 dp tall.
  large,

  /// Compact pill — 32 dp tall.
  small,
}

/// Figma icon placement (`30:1738`).
enum AppButtonIconPosition {
  /// Text centered; no icon (`Icon Position=None`).
  none,

  /// Icon pinned to the start edge; label stays centered (`Icon Position=Left`).
  left,

  /// Icon pinned to the end edge; label stays centered (`Icon Position=Right`).
  right,

  /// Icon + label grouped and centered together (`Icon Position=Side`).
  ///
  /// Use for CTAs like Figma `731:3785` (icon immediately before the label).
  center,
}

/// Resolved colours for one button render pass.
@immutable
class ButtonSurfaceColors {
  const ButtonSurfaceColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;

  bool get hasBorder => border.a > 0;
}

/// Per-[AppButtonIntent] color ramp + the shade steps used for a solid fill.
///
/// Shade steps intentionally differ per intent (e.g. warning's filled step is
/// `400`/`600` rather than `600`/`700`) to match the exact Figma-verified
/// values already shipped for `Type=Primary` and the warning CTA — this
/// preserves pixel-identical output for every combination that was already
/// live before the variant/intent split.
@immutable
class _IntentPalette {
  const _IntentPalette({
    required this.scale,
    required this.fillDefault,
    required this.fillPressed,
  });

  final ColorScale scale;
  final int fillDefault;
  final int fillPressed;
}

/// Figma `Controls / Buttons` token resolver.
abstract final class ButtonTokens {
  ButtonTokens._();

  static const double outlineBorderWidth = 1;
  static const double blockHeight = 48;
  static const double largeHeight = 48;
  static const double smallHeight = 32;
  static const double iconSize = 24;
  static const double smallIconSize = 18;
  static const double iconInset = 16;
  static const double sideIconGap = 8;

  static double minHeight(AppButtonSize size) => switch (size) {
    AppButtonSize.block => responsiveDimension(blockHeight),
    AppButtonSize.large => responsiveDimension(largeHeight),
    AppButtonSize.small => responsiveDimension(smallHeight),
  };

  static EdgeInsets padding(AppButtonSize size) => switch (size) {
    AppButtonSize.block || AppButtonSize.large => EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.sm,
    ),
    AppButtonSize.small => EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.sm,
    ),
  };

  static BorderRadius borderRadius() =>
      BorderRadius.circular(AppDimension.radiusPill);

  static TextStyle labelStyle(AppTypography typography) =>
      typography.labelLarge;

  /// Loading-spinner size — follows [size] so a `small` button doesn't get
  /// an oversized spinner relative to its 32 dp height.
  static double spinnerSize(AppButtonSize size) => switch (size) {
    AppButtonSize.block || AppButtonSize.large => responsiveDimension(
      iconSize,
    ),
    AppButtonSize.small => responsiveDimension(smallIconSize),
  };

  static double iconBoxSize() => responsiveDimension(iconSize);

  static double iconEdgeInset() => AppSpacing.lg;

  static _IntentPalette _paletteFor(AppButtonIntent intent, AppColors colors) {
    return switch (intent) {
      AppButtonIntent.standard => _IntentPalette(
        scale: colors.palettes.main,
        fillDefault: 600,
        fillPressed: 700,
      ),
      AppButtonIntent.warning => _IntentPalette(
        scale: colors.palettes.yellow,
        fillDefault: 400,
        fillPressed: 600,
      ),
      AppButtonIntent.destructive => _IntentPalette(
        scale: colors.palettes.red,
        fillDefault: 600,
        fillPressed: 700,
      ),
      AppButtonIntent.neutral => _IntentPalette(
        scale: colors.palettes.dark,
        fillDefault: 900,
        fillPressed: 950,
      ),
    };
  }

  /// Resolves Figma button colours for [variant] × [intent] × theme ×
  /// [WidgetState].
  static ButtonSurfaceColors resolve({
    required AppButtonVariant variant,
    required AppColors colors,
    required Brightness brightness,
    required Set<WidgetState> states,
    AppButtonIntent intent = AppButtonIntent.standard,
  }) {
    final isDark = brightness == Brightness.dark;
    final isDisabled = states.contains(WidgetState.disabled);
    final isPressed =
        states.contains(WidgetState.pressed) ||
        states.contains(WidgetState.focused);

    if (isDisabled) {
      return _disabled(
        variant,
        intent: intent,
        isDark: isDark,
        sky: colors.palettes.sky,
        dark: colors.palettes.dark,
        yellow: colors.palettes.yellow,
      );
    }

    final palette = _paletteFor(intent, colors);
    final dark = colors.palettes.dark;

    return switch (variant) {
      AppButtonVariant.primary => ButtonSurfaceColors(
        background: isPressed
            ? palette.scale[palette.fillPressed]
            : palette.scale[palette.fillDefault],
        foreground: dark.shade50,
        border: Colors.transparent,
      ),
      AppButtonVariant.secondary => _soft(
        palette.scale,
        intent: intent,
        isDark: isDark,
        isPressed: isPressed,
      ),
      AppButtonVariant.outline => _outline(
        palette.scale,
        intent: intent,
        isDark: isDark,
        isPressed: isPressed,
      ),
      AppButtonVariant.transparent => _transparent(
        palette.scale,
        intent: intent,
        isDark: isDark,
        isPressed: isPressed,
      ),
    };
  }

  /// Tonal (`secondary`) surface. `standard` keeps its exact, Figma-verified
  /// light/dark fork; `warning`/`destructive` (previously unreachable via the
  /// public `AppButton` API) follow the same 50/200/600/700 step pattern the
  /// legacy destructive-soft token already used.
  static ButtonSurfaceColors _soft(
    ColorScale scale, {
    required AppButtonIntent intent,
    required bool isDark,
    required bool isPressed,
  }) {
    if (intent == AppButtonIntent.standard) {
      if (isPressed) {
        return ButtonSurfaceColors(
          background: scale.shade100,
          foreground: scale.shade700,
          border: Colors.transparent,
        );
      }
      return ButtonSurfaceColors(
        background: isDark ? scale.shade100 : scale.shade50,
        foreground: isDark ? scale.shade700 : scale.shade600,
        border: Colors.transparent,
      );
    }
    if (intent == AppButtonIntent.neutral) {
      // Figma `6974:25087` — gray fill with a near-black label; the generic
      // branch below (mid-shade foreground) reads as too washed-out for a
      // secondary CTA that isn't brand-tinted.
      return ButtonSurfaceColors(
        background: isPressed ? scale.shade200 : scale.shade100,
        foreground: scale.shade900,
        border: Colors.transparent,
      );
    }
    return ButtonSurfaceColors(
      background: isPressed ? scale.shade200 : scale.shade50,
      foreground: isPressed ? scale.shade700 : scale.shade600,
      border: Colors.transparent,
    );
  }

  /// Bordered (`outline`) surface. `standard` keeps its exact light/dark
  /// fork; `warning`/`destructive` use a single, brightness-independent
  /// step pair (matches the legacy destructive-outline token).
  static ButtonSurfaceColors _outline(
    ColorScale scale, {
    required AppButtonIntent intent,
    required bool isDark,
    required bool isPressed,
  }) {
    if (intent == AppButtonIntent.standard) {
      final color = isPressed
          ? (isDark ? scale.shade600 : scale.shade700)
          : (isDark ? scale.shade100 : scale.shade600);
      return ButtonSurfaceColors(
        background: Colors.transparent,
        foreground: color,
        border: color,
      );
    }
    final color = isPressed ? scale.shade700 : scale.shade600;
    return ButtonSurfaceColors(
      background: Colors.transparent,
      foreground: color,
      border: color,
    );
  }

  /// Text-only (`transparent`/ghost) surface. All intents share the same
  /// shape, including `standard`'s tonal press-wash — extended to
  /// `warning`/`destructive` for a consistent press affordance since neither
  /// combination was reachable before this token merge.
  static ButtonSurfaceColors _transparent(
    ColorScale scale, {
    required AppButtonIntent intent,
    required bool isDark,
    required bool isPressed,
  }) {
    if (isPressed) {
      return ButtonSurfaceColors(
        background: isDark ? scale.shade100 : scale.shade50,
        foreground: scale.shade600,
        border: Colors.transparent,
      );
    }
    final color = intent == AppButtonIntent.standard
        ? (isDark ? scale.shade100 : scale.shade600)
        : scale.shade600;
    return ButtonSurfaceColors(
      background: Colors.transparent,
      foreground: color,
      border: Colors.transparent,
    );
  }

  /// Disabled is uniform across variants for `standard`/`destructive` (the
  /// neutral sky/dark ramp — Figma confirms `Primary/Disabled` and
  /// `Secondary/Disabled` are pixel-identical); `warning` keeps its own
  /// yellow-tinted disabled colours, matching the only Figma-verified
  /// disabled warning CTA.
  static ButtonSurfaceColors _disabled(
    AppButtonVariant variant, {
    required AppButtonIntent intent,
    required bool isDark,
    required ColorScale sky,
    required ColorScale dark,
    required ColorScale yellow,
  }) {
    if (intent == AppButtonIntent.warning) {
      return isDark
          ? ButtonSurfaceColors(
              background: yellow.shade800,
              foreground: dark.shade300,
              border: Colors.transparent,
            )
          : ButtonSurfaceColors(
              background: yellow.shade100,
              foreground: dark.shade500,
              border: Colors.transparent,
            );
    }

    final isGhostShape =
        variant == AppButtonVariant.outline ||
        variant == AppButtonVariant.transparent;

    if (isGhostShape) {
      final color = isDark ? dark.shade500 : dark.shade200;
      return ButtonSurfaceColors(
        background: Colors.transparent,
        foreground: color,
        border: color,
      );
    }

    return isDark
        ? ButtonSurfaceColors(
            background: dark.shade600,
            foreground: dark.shade300,
            border: Colors.transparent,
          )
        : ButtonSurfaceColors(
            background: sky.shade100,
            foreground: dark.shade500,
            border: Colors.transparent,
          );
  }
}
