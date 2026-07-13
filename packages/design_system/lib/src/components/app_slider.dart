import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/slider_tokens.dart';
import 'package:flutter/material.dart';

/// Figma `Controls / Sliders` (`40:7585`).
class AppSlider extends StatelessWidget {
  const AppSlider({
    required this.value, required this.onChanged, super.key,
    this.min = 0,
    this.max = 1,
    this.type = AppSliderType.single,
    this.rangeValues,
    this.onRangeChanged,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final AppSliderType type;
  final RangeValues? rangeValues;
  final ValueChanged<RangeValues>? onRangeChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final brightness = Theme.of(context).brightness;

    final sliderTheme = SliderTheme(
      data: SliderTokens.sliderTheme(
        colors: colors,
        brightness: brightness,
      ),
      child: type == AppSliderType.range
          ? RangeSlider(
              values: rangeValues ?? RangeValues(min, max),
              min: min,
              max: max,
              onChanged: onRangeChanged,
            )
          : Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
    );

    return sliderTheme;
  }
}
