import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/stepper_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma `Controls / Steppers` (`40:7513`).
class AppStepper extends StatelessWidget {
  const AppStepper({
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
    super.key,
    this.size = AppStepperSize.large,
    this.min,
    this.max,
  });

  final int value;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final AppStepperSize size;
  final int? min;
  final int? max;

  bool get _canDecrement =>
      onDecrement != null && (min == null || value > min!);

  bool get _canIncrement =>
      onIncrement != null && (max == null || value < max!);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final brightness = Theme.of(context).brightness;
    final spec = StepperTokens.resolve(
      colors: colors,
      typography: typography,
      brightness: brightness,
    );

    final iconSize = spec.iconSize(size);

    return Container(
      width: spec.width(size),
      height: spec.height(size),
      decoration: BoxDecoration(
        borderRadius: spec.borderRadius,
        border: Border.all(color: spec.borderColor),
      ),
      child: Row(
        children: [
          _StepperButton(
            icon: Icons.remove,
            iconSize: iconSize,
            inset: spec.iconInset(size),
            color: _canDecrement
                ? spec.decrementColor
                : spec.disabledIconColor,
            onTap: _canDecrement ? onDecrement : null,
          ),
          Expanded(
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: spec.valueStyle,
            ),
          ),
          _StepperButton(
            icon: Icons.add,
            iconSize: iconSize,
            inset: spec.iconInset(size),
            color: _canIncrement
                ? spec.incrementColor
                : spec.disabledIconColor,
            onTap: _canIncrement ? onIncrement : null,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.iconSize,
    required this.inset,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final double iconSize;
  final double inset;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.all(inset),
        child: Icon(icon, size: iconSize, color: color),
      ),
    );
  }
}
