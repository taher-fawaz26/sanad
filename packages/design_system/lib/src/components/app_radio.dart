import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/radio_tokens.dart';
import 'package:flutter/material.dart';

/// Figma `Controls / Radio Buttons` (`40:7530`).
class AppRadio<T> extends StatelessWidget {
  const AppRadio({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    super.key,
  });

  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final brightness = Theme.of(context).brightness;
    final spec = RadioTokens.resolve(
      colors: colors,
      brightness: brightness,
    );
    final enabled = onChanged != null;
    final selected = value == groupValue;

    return Semantics(
      checked: selected,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled ? () => onChanged!(value) : null,
        child: SizedBox(
          width: spec.size,
          height: spec.size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? (enabled
                        ? spec.selectedFillColor
                        : spec.selectedDisabledFillColor)
                  : Colors.transparent,
              border: selected
                  ? null
                  : Border.all(
                      color: enabled
                          ? spec.unselectedBorderColor
                          : spec.unselectedDisabledBorderColor,
                    ),
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: spec.size * RadioTokens.innerDotRatio,
                      height: spec.size * RadioTokens.innerDotRatio,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: enabled
                            ? spec.innerDotColor
                            : spec.disabledInnerDotColor,
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
