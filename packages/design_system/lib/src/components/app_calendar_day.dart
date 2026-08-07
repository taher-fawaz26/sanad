import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/date_picker_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma `_Partials / Date` (`194:4474`) — calendar day cell.
class AppCalendarDay extends StatelessWidget {
  const AppCalendarDay({
    required this.day,
    super.key,
    this.isSelected = false,
    this.onTap,
    this.enabled = true,
  });

  final int day;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final brightness = Theme.of(context).brightness;
    final spec = DatePickerTokens.dayCell(
      colors: colors,
      typography: typography,
      brightness: brightness,
    );

    final active = isSelected && enabled;
    final background = active
        ? spec.activeBackgroundColor
        : spec.defaultBackgroundColor;
    final foreground = active ? spec.activeTextColor : spec.defaultTextColor;

    return Semantics(
      button: onTap != null,
      selected: active,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: spec.size,
          height: spec.size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: spec.borderRadius,
          ),
          child: Text(
            '$day',
            style: spec.textStyle.copyWith(color: foreground),
          ),
        ),
      ),
    );
  }
}
