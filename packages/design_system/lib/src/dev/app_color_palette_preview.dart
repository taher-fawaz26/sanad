import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/colors/color_scale.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma color palette section (`40:4600`) — palette ramp preview.
///
/// Dev-only. Not exported from any barrel — for internal showcase/QA use
/// only, imported via its deep `package:design_system/src/dev/...` path.
class AppColorPalettePreview extends StatelessWidget {
  const AppColorPalettePreview({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final palettes = colors.palettes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PaletteRow(name: 'main', scale: palettes.main),
        SizedBox(height: AppSpacing.lg),
        _PaletteRow(name: 'accent', scale: palettes.accent),
        SizedBox(height: AppSpacing.lg),
        _PaletteRow(name: 'dark', scale: palettes.dark),
        SizedBox(height: AppSpacing.lg),
        _PaletteRow(name: 'sky', scale: palettes.sky),
        SizedBox(height: AppSpacing.lg),
        _PaletteRow(name: 'yellow', scale: palettes.yellow),
        SizedBox(height: AppSpacing.lg),
        _PaletteRow(name: 'red', scale: palettes.red),
      ],
    );
  }
}

class _PaletteRow extends StatelessWidget {
  const _PaletteRow({
    required this.name,
    required this.scale,
  });

  final String name;
  final ColorScale scale;

  static const _steps = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950];

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: typography.smallNormal.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _steps.map((step) {
            return _Swatch(step: step, color: scale[step]);
          }).toList(),
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.step,
    required this.color,
  });

  final int step;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: context.appColors.border.withValues(alpha: 0.5),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          '$step',
          style: typography.tinyNormal.copyWith(
            color: context.appColors.textMuted,
          ),
        ),
      ],
    );
  }
}
