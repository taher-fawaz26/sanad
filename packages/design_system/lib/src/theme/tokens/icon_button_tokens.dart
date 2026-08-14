import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:flutter/material.dart';

/// Figma icon button size tier (`62:731`).
enum AppIconButtonSize {
  /// 28 dp touch target, 20 dp icon.
  small,

  /// 40 dp touch target, 24 dp icon.
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
    Color? iconColor,
  }) {
    final (dimension, iconDimension) = switch (size) {
      AppIconButtonSize.small => (
        AppDimension.iconButtonSm,
        AppDimension.iconMd,
      ),
      AppIconButtonSize.large => (
        AppDimension.iconButtonLg,
        AppDimension.iconMenu,
      ),
    };

    return IconButtonStyleSpec(
      size: dimension,
      iconSize: iconDimension,
      borderRadius: BorderRadius.circular(AppDimension.radiusSm),
      iconColor: iconColor ?? colors.textSecondary,
    );
  }
}
