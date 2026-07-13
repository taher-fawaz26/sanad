import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/chip_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma `Controls / Chips: Pill` (`40:7367`).
class AppChip extends StatelessWidget {
  const AppChip({
    required this.label, super.key,
    this.selected = false,
    this.style = AppChipStyle.solid,
    this.tone = AppChipTone.normal,
    this.size = AppChipSize.compact,
    this.icon,
    this.iconPosition = AppChipIconPosition.none,
    this.onTap,
  });

  final String label;
  final bool selected;
  final AppChipStyle style;
  final AppChipTone tone;
  final AppChipSize size;
  final Widget? icon;
  final AppChipIconPosition iconPosition;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final brightness = Theme.of(context).brightness;
    final clear = colors.palettes.white.withValues(alpha: 0);
    final surface = ChipTokens.resolve(
      style: style,
      selected: selected,
      colors: colors,
      brightness: brightness,
      tone: tone,
    );
    final textStyle = ChipTokens.labelStyle(typography, surface);
    final minHeight = ChipTokens.minHeight(size);
    final radius = ChipTokens.borderRadius(size);
    final width = ChipTokens.expandedWidthValue(size);
    final effectiveIconPosition =
        icon == null ? AppChipIconPosition.none : iconPosition;

    final content = Row(
      mainAxisSize:
          size == AppChipSize.expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (effectiveIconPosition == AppChipIconPosition.left) ...[
          SizedBox(
            width: AppDimension.iconCompact,
            height: AppDimension.iconCompact,
            child: icon,
          ),
          SizedBox(width: ChipTokens.iconGapSize()),
        ],
        Text(label, style: textStyle),
        if (effectiveIconPosition == AppChipIconPosition.right) ...[
          SizedBox(width: ChipTokens.iconGapSize()),
          SizedBox(
            width: AppDimension.iconCompact,
            height: AppDimension.iconCompact,
            child: icon,
          ),
        ],
      ],
    );

    return Material(
      color: clear,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashFactory: NoSplash.splashFactory,
        highlightColor: clear,
        child: Ink(
          width: width,
          height: minHeight,
          padding: ChipTokens.padding(iconPosition: effectiveIconPosition),
          decoration: BoxDecoration(
            color: surface.background,
            borderRadius: radius,
            border: surface.hasBorder
                ? Border.all(
                    color: surface.border,
                    width: AppDimension.borderHairline,
                  )
                : null,
          ),
          child: Center(child: content),
        ),
      ),
    );
  }
}
