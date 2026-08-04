import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/colors/field_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Shared field label with an optional red required asterisk and [suffix].
class AppFieldLabel extends StatelessWidget {
  const AppFieldLabel({
    required this.label,
    super.key,
    this.isRequired = false,
    this.suffix,
  });

  final String label;
  final bool isRequired;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final brightness = Theme.of(context).brightness;
    final style = FieldTokens.labelStyle(typography, colors, brightness);

    final labelWidget = isRequired
        ? Text.rich(
            TextSpan(
              style: style,
              children: [
                TextSpan(text: label),
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: FieldTokens.errorBorder(colors, brightness),
                  ),
                ),
              ],
            ),
          )
        : Text(label, style: style);

    if (suffix == null) {
      return labelWidget;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        labelWidget,
        SizedBox(width: AppSpacing.sm),
        suffix!,
      ],
    );
  }
}
