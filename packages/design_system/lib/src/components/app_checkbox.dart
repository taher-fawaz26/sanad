import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/checkbox_tokens.dart';
import 'package:flutter/material.dart';

/// Figma `Controls / Checkboxes` (`40:7543`).
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    required this.value, required this.onChanged, super.key,
    this.tristate = false,
  });

  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final bool tristate;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final brightness = Theme.of(context).brightness;
    final spec = CheckboxTokens.resolve(
      colors: colors,
      brightness: brightness,
    );
    final enabled = onChanged != null;
    final selected = value ?? false;

    return Semantics(
      checked: value ?? false,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled
            ? () => onChanged!(tristate && (value ?? false) ? null : !selected)
            : null,
        child: SizedBox(
          width: spec.size,
          height: spec.size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected
                  ? (enabled
                      ? spec.selectedFillColor
                      : spec.selectedDisabledFillColor)
                  : Colors.transparent,
              borderRadius: spec.borderRadius,
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : (enabled
                        ? spec.unselectedBorderColor
                        : spec.unselectedDisabledBorderColor),
                width: spec.borderWidth,
              ),
            ),
            child: selected
                ? Icon(
                    Icons.check,
                    size: spec.size * 0.7,
                    color: enabled
                        ? spec.checkColor
                        : spec.disabledCheckColor,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
