import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/progress_tokens.dart';
import 'package:flutter/material.dart';

/// Figma `Views / Progress Bars` (`40:9160`).
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    required this.value,
    super.key,
    this.min = 0,
    this.max = 1,
    this.height,
    this.trackColor,
    this.fillColor,
    this.borderRadius,
  });

  final double value;
  final double min;
  final double max;

  /// Overrides the token-resolved bar height. Omit to use the default
  /// (`ProgressTokens.height`).
  final double? height;

  /// Overrides the token-resolved track color. Omit to use the theme default.
  final Color? trackColor;

  /// Overrides the token-resolved fill color. Omit to use `colors.primary`.
  final Color? fillColor;

  /// Overrides the token-resolved corner radius. Omit to use the theme
  /// default (pill-shaped).
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final brightness = Theme.of(context).brightness;
    final spec = ProgressTokens.resolve(
      colors: colors,
      brightness: brightness,
    );

    final fraction = ((value - min) / (max - min)).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: borderRadius ?? spec.borderRadius,
      child: SizedBox(
        height: height ?? spec.height,
        child: Stack(
          children: [
            Container(color: trackColor ?? spec.trackColor),
            FractionallySizedBox(
              widthFactor: fraction,
              child: Container(color: fillColor ?? spec.fillColor),
            ),
          ],
        ),
      ),
    );
  }
}
