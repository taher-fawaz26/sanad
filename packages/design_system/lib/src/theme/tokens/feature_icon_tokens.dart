import 'package:core/core.dart';
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/colors/color_scale.dart';
import 'package:flutter/material.dart';

/// Figma Featured Icon size (`751:4005`).
enum AppFeatureIconSize {
  /// 24 dp container, 12 dp icon.
  xs,

  /// 32 dp container, 16 dp icon.
  sm,

  /// 40 dp container, 20 dp icon.
  md,

  /// 48 dp container, 24 dp icon.
  lg,

  /// 56 dp container, 28 dp icon.
  xl,
}

/// Figma Featured Icon color (`751:4005`).
enum AppFeatureIconColor {
  primary,
  gray,
  error,
  warning,
  success,
}

/// Figma Featured Icon theme (`751:4005`).
enum AppFeatureIconTheme {
  /// Single filled circle (`Light circle`).
  lightCircle,

  /// Filled circle with lighter outer ring (`Light circle outline`).
  lightCircleOutline,
}

/// Resolved styling for [AppFeatureIcon].
@immutable
class FeatureIconStyleSpec {
  const FeatureIconStyleSpec({
    required this.containerSize,
    required this.iconSize,
    required this.outlineBorderWidth,
    required this.iconColor,
    required this.backgroundColor,
    required this.outlineColor,
    required this.defaultIconAsset,
  });

  final double containerSize;
  final double iconSize;
  final double outlineBorderWidth;
  final Color iconColor;
  final Color backgroundColor;
  final Color outlineColor;
  final String defaultIconAsset;
}

/// Figma `Featured Icon` (`751:4005`) token resolver.
abstract final class FeatureIconTokens {
  FeatureIconTokens._();

  static FeatureIconStyleSpec resolve({
    required AppFeatureIconSize size,
    required AppFeatureIconColor color,
    required AppFeatureIconTheme theme,
    required AppColors colors,
  }) {
    final (containerSize, iconSize, outlineBorderWidth) = switch (size) {
      AppFeatureIconSize.xs => (
          responsiveDimension(24),
          responsiveDimension(12),
          responsiveDimension(2),
        ),
      AppFeatureIconSize.sm => (
          responsiveDimension(32),
          responsiveDimension(16),
          responsiveDimension(4),
        ),
      AppFeatureIconSize.md => (
          responsiveDimension(40),
          responsiveDimension(20),
          responsiveDimension(6),
        ),
      AppFeatureIconSize.lg => (
          responsiveDimension(48),
          responsiveDimension(24),
          responsiveDimension(8),
        ),
      AppFeatureIconSize.xl => (
          responsiveDimension(56),
          responsiveDimension(28),
          responsiveDimension(10),
        ),
    };

    final (iconColor, backgroundColor, outlineColor, defaultIconAsset) =
        _surface(color: color, colors: colors);

    return FeatureIconStyleSpec(
      containerSize: containerSize,
      iconSize: iconSize,
      outlineBorderWidth:
          theme == AppFeatureIconTheme.lightCircleOutline
              ? outlineBorderWidth
              : 0,
      iconColor: iconColor,
      backgroundColor: backgroundColor,
      outlineColor: outlineColor,
      defaultIconAsset: defaultIconAsset,
    );
  }

  static (Color, Color, Color, String) _surface({
    required AppFeatureIconColor color,
    required AppColors colors,
  }) {
    final ColorScale ramp;
    final String iconAsset;
    final int iconShade;

    switch (color) {
      case AppFeatureIconColor.primary:
        ramp = colors.palettes.main;
        iconAsset = AppSvgs.zap;
        iconShade = 600;
      case AppFeatureIconColor.gray:
        ramp = colors.palettes.dark;
        iconAsset = AppSvgs.zap;
        iconShade = 600;
      case AppFeatureIconColor.error:
        ramp = colors.palettes.red;
        iconAsset = AppSvgs.alertCircle;
        iconShade = 600;
      case AppFeatureIconColor.warning:
        ramp = colors.palettes.yellow;
        iconAsset = AppSvgs.alertTriangle;
        iconShade = 600;
      case AppFeatureIconColor.success:
        ramp = colors.palettes.main;
        iconAsset = AppSvgs.checkCircle;
        iconShade = 600;
    }

    return (ramp[iconShade], ramp[100], ramp[50], iconAsset);
  }
}
