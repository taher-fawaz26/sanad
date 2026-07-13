import 'package:design_system/src/theme/tokens/switch_tokens.dart';
import 'package:flutter/material.dart';

/// Figma `Controls / Switches` (`40:7496`).
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    required this.value, required this.onChanged, super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final spec = Theme.of(context).extension<AppSwitchTheme>()!.spec;
    final enabled = onChanged != null;

    return Semantics(
      toggled: value,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled ? () => onChanged!(!value) : null,
        child: AnimatedContainer(
          duration: spec.animationDuration,
          width: spec.trackWidth,
          height: spec.trackHeight,
          decoration: BoxDecoration(
            color: spec.trackColor(value: value, enabled: enabled),
            borderRadius: spec.trackRadius,
            border: spec.trackBorder(value: value, enabled: enabled),
          ),
          child: AnimatedAlign(
            duration: spec.animationDuration,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: spec.knobSize,
              height: spec.knobSize,
              margin: EdgeInsets.all(spec.knobInset),
              decoration: BoxDecoration(
                color: spec.knobColor(value: value, enabled: enabled),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
