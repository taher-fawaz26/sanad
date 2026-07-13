import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/colors/color_scale.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma `Controls / Buttons` (`30:1738`) — resolved surface colours.
enum AppButtonType {
  /// Figma `Type=Primary` — solid main fill.
  primary,

  /// Figma `Type=Secondary` — tonal main surface.
  secondary,

  /// Figma `Type=Outline` — bordered, transparent fill.
  outline,

  /// Figma `Type=Transparent` — text-only / ghost.
  transparent,
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

/// Figma `Controls / Buttons` token resolver.
abstract final class ButtonTokens {
  ButtonTokens._();

  static const double outlineBorderWidth = 1;
  static const double blockHeight = 48;
  static const double largeHeight = 48;
  static const double smallHeight = 32;
  static const double iconSize = 24;
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

  static double iconBoxSize() => responsiveDimension(iconSize);

  static double iconEdgeInset() => AppSpacing.lg;

  /// Resolves Figma button colours for [type] × theme × [WidgetState].
  static ButtonSurfaceColors resolve({
    required AppButtonType type,
    required AppColors colors,
    required Brightness brightness,
    required Set<WidgetState> states,
  }) {
    final isDark = brightness == Brightness.dark;
    final main = colors.palettes.main;
    final dark = colors.palettes.dark;
    final sky = colors.palettes.sky;

    final isDisabled = states.contains(WidgetState.disabled);
    final isPressed =
        states.contains(WidgetState.pressed) ||
        states.contains(WidgetState.focused);

    if (isDisabled) {
      return _disabled(type, isDark: isDark, main: main, dark: dark, sky: sky);
    }
    if (isPressed) {
      return _pressed(type, isDark: isDark, main: main, dark: dark);
    }
    return _default(type, isDark: isDark, main: main, dark: dark);
  }

  static ButtonSurfaceColors _default(
    AppButtonType type, {
    required bool isDark,
    required ColorScale main,
    required ColorScale dark,
  }) {
    return switch (type) {
      AppButtonType.primary => ButtonSurfaceColors(
        background: main.shade600,
        foreground: dark.shade50,
        border: Colors.transparent,
      ),
      AppButtonType.secondary => ButtonSurfaceColors(
        background: isDark ? main.shade100 : main.shade50,
        foreground: isDark ? main.shade700 : main.shade600,
        border: Colors.transparent,
      ),
      AppButtonType.outline => ButtonSurfaceColors(
        background: Colors.transparent,
        foreground: isDark ? main.shade100 : main.shade600,
        border: isDark ? main.shade100 : main.shade600,
      ),
      AppButtonType.transparent => ButtonSurfaceColors(
        background: Colors.transparent,
        foreground: isDark ? main.shade100 : main.shade600,
        border: Colors.transparent,
      ),
    };
  }

  static ButtonSurfaceColors _pressed(
    AppButtonType type, {
    required bool isDark,
    required ColorScale main,
    required ColorScale dark,
  }) {
    return switch (type) {
      AppButtonType.primary => ButtonSurfaceColors(
        background: main.shade700,
        foreground: dark.shade50,
        border: Colors.transparent,
      ),
      AppButtonType.secondary => ButtonSurfaceColors(
        background: main.shade100,
        foreground: main.shade700,
        border: Colors.transparent,
      ),
      AppButtonType.outline => ButtonSurfaceColors(
        background: Colors.transparent,
        foreground: isDark ? main.shade600 : main.shade700,
        border: isDark ? main.shade600 : main.shade700,
      ),
      AppButtonType.transparent => ButtonSurfaceColors(
        background: isDark ? main.shade100 : main.shade50,
        foreground: isDark ? main.shade600 : main.shade600,
        border: Colors.transparent,
      ),
    };
  }

  static ButtonSurfaceColors _disabled(
    AppButtonType type, {
    required bool isDark,
    required ColorScale main,
    required ColorScale dark,
    required ColorScale sky,
  }) {
    if (isDark) {
      return switch (type) {
        AppButtonType.outline || AppButtonType.transparent =>
          ButtonSurfaceColors(
            background: Colors.transparent,
            foreground: dark.shade500,
            border: dark.shade500,
          ),
        AppButtonType.primary || AppButtonType.secondary =>
          ButtonSurfaceColors(
            background: dark.shade600,
            foreground: dark.shade300,
            border: Colors.transparent,
          ),
      };
    }

    return switch (type) {
      AppButtonType.outline || AppButtonType.transparent => ButtonSurfaceColors(
        background: Colors.transparent,
        foreground: dark.shade200,
        border: dark.shade200,
      ),
      AppButtonType.primary || AppButtonType.secondary => ButtonSurfaceColors(
        background: sky.shade100,
        foreground: dark.shade500,
        border: Colors.transparent,
      ),
    };
  }

  /// Maps legacy [ButtonStyleType] + [ButtonVariant] to Figma [AppButtonType].
  static AppButtonType fromLegacy({
    required ButtonStyleType styleType,
    required ButtonVariant variant,
  }) {
    if (styleType == ButtonStyleType.danger) {
      return switch (variant) {
        ButtonVariant.filled || ButtonVariant.soft => AppButtonType.primary,
        ButtonVariant.outline => AppButtonType.outline,
        _ => AppButtonType.transparent,
      };
    }

    return switch (variant) {
      ButtonVariant.filled => switch (styleType) {
        ButtonStyleType.secondary => AppButtonType.secondary,
        _ => AppButtonType.primary,
      },
      ButtonVariant.soft => AppButtonType.secondary,
      ButtonVariant.outline || ButtonVariant.dashed => AppButtonType.outline,
      ButtonVariant.ghost => AppButtonType.transparent,
    };
  }

  /// Danger actions use the red ramp while keeping Figma type geometry.
  static bool usesDestructivePalette(ButtonStyleType styleType) =>
      styleType == ButtonStyleType.danger;

  static ButtonSurfaceColors destructive({
    required AppColors colors,
    required Brightness brightness,
    required ButtonVariant variant,
    required Set<WidgetState> states,
  }) {
    final red = colors.palettes.red;
    final dark = colors.palettes.dark;
    final isDark = brightness == Brightness.dark;
    final isDisabled = states.contains(WidgetState.disabled);
    final isPressed = states.contains(WidgetState.pressed);

    if (isDisabled) {
      return _disabled(
        variant == ButtonVariant.outline
            ? AppButtonType.outline
            : AppButtonType.primary,
        isDark: isDark,
        main: colors.palettes.main,
        dark: dark,
        sky: colors.palettes.sky,
      );
    }

    return switch (variant) {
      ButtonVariant.filled => ButtonSurfaceColors(
        background: isPressed ? red.shade700 : red.shade600,
        foreground: dark.shade50,
        border: Colors.transparent,
      ),
      ButtonVariant.soft => ButtonSurfaceColors(
        background: isPressed ? red.shade200 : red.shade50,
        foreground: isPressed ? red.shade700 : red.shade600,
        border: Colors.transparent,
      ),
      ButtonVariant.outline => ButtonSurfaceColors(
        background: Colors.transparent,
        foreground: isPressed ? red.shade700 : red.shade600,
        border: isPressed ? red.shade700 : red.shade600,
      ),
      _ => ButtonSurfaceColors(
        background: Colors.transparent,
        foreground: isPressed ? red.shade700 : red.shade600,
        border: Colors.transparent,
      ),
    };
  }
}

/// Legacy semantic intent — mapped to [AppButtonType] via `fromLegacy`.
enum ButtonStyleType { primary, secondary, danger, neutral, third }

/// Legacy visual appearance — mapped to [AppButtonType] via `fromLegacy`.
enum ButtonVariant { filled, outline, ghost, dashed, soft }
