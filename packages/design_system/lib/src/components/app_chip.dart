import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/chip_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma `Controls / Chips: Pill` (`40:7367`).
class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    super.key,
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
    final expandedWidth = ChipTokens.expandedWidthValue(size);
    final effectiveIconPosition = icon == null
        ? AppChipIconPosition.none
        : iconPosition;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
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
        Flexible(
          child: Text(
            label,
            style: textStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
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

    // Compact chips must size to their content. `Ink` with only a height
    // expands to the parent's max width (e.g. inside [Wrap]), which makes
    // every chip full-bleed — never set a null width on an expanding box.
    final chip = Material(
      color: clear,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashFactory: NoSplash.splashFactory,
        highlightColor: clear,
        child: Ink(
          width: expandedWidth,
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

    if (expandedWidth != null) return chip;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: IntrinsicWidth(child: chip),
        );
      },
    );
  }
}
