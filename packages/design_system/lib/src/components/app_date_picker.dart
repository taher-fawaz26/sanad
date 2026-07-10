import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/date_picker_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma `Controls / Date Pickers` (`40:7644`).
///
/// Wraps Material [showDatePicker] with Sanad theme tokens.
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
  String? cancelText,
  String? confirmText,
}) {
  final colors = context.appColors;
  final typography = context.appTypography;
  final brightness = Theme.of(context).brightness;

  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: helpText,
    cancelText: cancelText,
    confirmText: confirmText,
    builder: (context, child) {
      final theme = Theme.of(context);
      return Theme(
        data: theme.copyWith(
          datePickerTheme: DatePickerTokens.datePickerTheme(
            colors: colors,
            typography: typography,
            brightness: brightness,
          ),
          colorScheme: theme.colorScheme.copyWith(
            primary: colors.primary,
            onPrimary: colors.white,
          ),
        ),
        child: child!,
      );
    },
  );
}
