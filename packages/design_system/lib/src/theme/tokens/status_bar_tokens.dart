import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Figma `Views / Native Status Bar` (`40:7874`) — system overlay presets.
abstract final class StatusBarTokens {
  StatusBarTokens._();

  static SystemUiOverlayStyle resolve({
    required AppColors colors,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    final foreground = isDark ? colors.white : colors.palettes.dark.shade950;

    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: colors.surface,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: colors.divider,
    ).copyWith(
      statusBarIconBrightness:
          foreground.computeLuminance() > 0.5
              ? Brightness.dark
              : Brightness.light,
    );
  }
}
