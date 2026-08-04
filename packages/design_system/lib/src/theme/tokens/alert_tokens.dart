import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/status_surface_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:design_system/src/theme/typography/responsive_font_scale.dart';
import 'package:flutter/material.dart';

/// Figma inline alert variants (`3821:19134` – `3821:19202`).
enum AppAlertType {
  /// Yellow — expiring / caution copy (`3821:19134`).
  warning,

  /// Red — expired / critical copy (`3821:19157`).
  error,

  /// Blue — under review copy (`3821:19180`).
  info,

  /// Soft red — rejected document copy (`3821:19202`).
  rejected,
}

@immutable
class AlertStyleSpec {
  const AlertStyleSpec({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textStyle,
    required this.padding,
    required this.contentGap,
    required this.borderRadius,
    required this.borderWidth,
    required this.iconSize,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final TextStyle textStyle;
  final EdgeInsets padding;
  final double contentGap;
  final BorderRadius borderRadius;
  final double borderWidth;
  final double iconSize;
}

/// Figma `Alert` banner tokens (`3821:19134` – `3821:19202`).
abstract final class AlertTokens {
  AlertTokens._();

  static const double _labelFontSize = 12;
  static const double _labelLineHeight = 20 / 12;

  static AlertStyleSpec resolve({
    required AppAlertType type,
    required AppTypography typography,
    required AppColors colors,
    required Brightness brightness,
  }) {
    final (background, border, icon) = StatusSurfaceTokens.alert(
      type: type,
      colors: colors,
      brightness: brightness,
    );

    return AlertStyleSpec(
      backgroundColor: background,
      borderColor: border,
      iconColor: icon,
      padding: EdgeInsets.all(AppSpacing.lg),
      contentGap: AppSpacing.lg,
      borderRadius: BorderRadius.circular(AppDimension.radiusMd),
      borderWidth: responsiveDimension(1.5),
      iconSize: AppDimension.iconMenu,
      textStyle: typography.smallNormal.copyWith(
        fontSize: _labelFontSize.rfs,
        height: _labelLineHeight,
        fontWeight: FontWeight.w400,
        color: colors.textSecondary,
      ),
    );
  }
}
