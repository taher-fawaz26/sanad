import 'package:design_system/src/components/app_radio.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma labeled radio row — `Controls / Radio Buttons` (`40:7530`).
class AppRadioTile<T> extends StatelessWidget {
  const AppRadioTile({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.label,
    super.key,
  });

  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final String label;

  bool get _selected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          AppRadio<T>(
            value: value,
            groupValue: groupValue,
            onChanged: onChanged,
          ),
          SizedBox(width: AppSpacing.md),
          Text(
            label,
            style: typography.regularNormal.copyWith(
              fontWeight: FontWeight.w500,
              height: 16 / 16,
              color: _selected ? colors.primary : colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Vertical group of [AppRadioTile] options.
class AppRadioGroup<T> extends StatelessWidget {
  const AppRadioGroup({
    required this.value,
    required this.onChanged,
    required this.options,
    super.key,
    this.spacing = 20,
  });

  final T? value;
  final ValueChanged<T?>? onChanged;
  final List<AppRadioOption<T>> options;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < options.length; i++) ...[
          AppRadioTile<T>(
            value: options[i].value,
            groupValue: value,
            onChanged: onChanged,
            label: options[i].label,
          ),
          if (i < options.length - 1)
            SizedBox(height: responsiveSpacing(spacing)),
        ],
      ],
    );
  }
}

/// Label + value pair for [AppRadioGroup].
class AppRadioOption<T> {
  const AppRadioOption({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}
