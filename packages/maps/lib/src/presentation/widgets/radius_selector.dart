import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:maps/src/presentation/models/radius_preset.dart';
import 'package:maps/src/presentation/utils/radius_format.dart';

class RadiusSelector extends StatelessWidget {
  const RadiusSelector({
    required this.radiusKm,
    required this.onChanged,
    this.label,
    this.min = 1,
    this.max = 30,
    this.presets = const [],
    super.key,
  });

  final double radiusKm;
  final ValueChanged<double> onChanged;
  final String? label;
  final double min;
  final double max;
  final List<RadiusPreset> presets;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (label != null)
              Expanded(
                child: Text(label!, style: typography.regularNormal),
              ),
            Text(
              formatRadiusKm(radiusKm),
              style: typography.regularNormal.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.sm),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: colors.primary,
            inactiveTrackColor: colors.onSurface.withValues(alpha: 0.12),
            thumbColor: colors.primary,
            overlayColor: colors.primary.withValues(alpha: 0.12),
          ),
          child: Slider(
            value: radiusKm.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        if (presets.isNotEmpty) ...[
          SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: presets.map((preset) {
              final selected =
                  (radiusKm - preset.radiusKm).abs() < 0.1;
              return ChoiceChip(
                label: Text(preset.label),
                selected: selected,
                onSelected: (_) => onChanged(preset.radiusKm),
                selectedColor: colors.primary.withValues(alpha: 0.15),
                labelStyle: typography.smallNormal.copyWith(
                  color: selected ? colors.primary : colors.onSurface,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
