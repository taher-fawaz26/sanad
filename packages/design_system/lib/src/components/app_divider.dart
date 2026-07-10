import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/divider_tokens.dart';
import 'package:flutter/material.dart';

/// Figma `Views / Dividers` (`53:2097`).
class AppDivider extends StatelessWidget {
  const AppDivider({
    super.key,
    this.thickness = AppDividerThickness.thin,
    this.padded = false,
  });

  final AppDividerThickness thickness;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final brightness = Theme.of(context).brightness;
    final spec = DividerTokens.resolve(
      colors: colors,
      brightness: brightness,
    );

    final height =
        thickness == AppDividerThickness.thin
            ? spec.thinHeight
            : spec.thickHeight;
    final color =
        thickness == AppDividerThickness.thin
            ? spec.thinColor
            : spec.thickColor;

    final divider = Container(
      height: height,
      color: color,
    );

    if (!padded) {
      return divider;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spec.paddedInset),
      child: divider,
    );
  }
}
