import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/button_tokens.dart';
import 'package:flutter/material.dart';

/// Figma icon button size tier (`62:731`).
///
/// The tappable hit target (44/48 dp) meets the platform minimum-touch-target
/// guideline independently of the visual glyph size (20/24 dp) — the extra
/// tap area is transparent, so it doesn't change how the button looks.
enum AppIconButtonSize {
  /// 44 dp touch target, 20 dp icon.
  small,

  /// 48 dp touch target, 24 dp icon.
  large,
}

/// Resolved styling for [AppIconButton].
@immutable
class IconButtonStyleSpec {
  const IconButtonStyleSpec({
    required this.size,
    required this.iconSize,
    required this.borderRadius,
    required this.iconColor,
  });

  final double size;
  final double iconSize;
  final BorderRadius borderRadius;
  final Color iconColor;
}

/// Figma `icon buttons` (`62:731`) token resolver.
abstract final class IconButtonTokens {
  IconButtonTokens._();

  static IconButtonStyleSpec resolve({
    required AppIconButtonSize size,
    required AppColors colors,
    AppButtonIntent intent = AppButtonIntent.standard,
    Color? iconColor,
  }) {
    final (dimension, iconDimension) = switch (size) {
      AppIconButtonSize.small => (
        responsiveDimension(44),
        AppDimension.iconMd,
      ),
      AppIconButtonSize.large => (
        AppDimension.buttonMd, // 48 dp — shared with AppButton's medium height.
        AppDimension.iconMenu,
      ),
    };

    return IconButtonStyleSpec(
      size: dimension,
      iconSize: iconDimension,
      borderRadius: BorderRadius.circular(AppDimension.radiusSm),
      iconColor: iconColor ?? _defaultColor(intent, colors),
    );
  }

  static Color _defaultColor(AppButtonIntent intent, AppColors colors) =>
      switch (intent) {
        AppButtonIntent.standard => colors.textSecondary,
        AppButtonIntent.warning => colors.warning,
        AppButtonIntent.destructive => colors.error,
      };
}
