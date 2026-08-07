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
  });

  final double value;
  final double min;
  final double max;

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
      borderRadius: spec.borderRadius,
      child: SizedBox(
        height: spec.height,
        child: Stack(
          children: [
            Container(color: spec.trackColor),
            FractionallySizedBox(
              widthFactor: fraction,
              child: Container(color: spec.fillColor),
            ),
          ],
        ),
      ),
    );
  }
}
