import 'package:design_system/design_system.dart' show AppRadio;
import 'package:design_system/src/components/app_radio.dart' show AppRadio;
import 'package:design_system/src/components/components.dart' show AppRadio;
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:flutter/material.dart';

/// Resolved styling for [AppRadio].
@immutable
class RadioStyleSpec {
  const RadioStyleSpec({
    required this.size,
    required this.unselectedBorderColor,
    required this.unselectedDisabledBorderColor,
    required this.selectedFillColor,
    required this.selectedDisabledFillColor,
    required this.innerDotColor,
    required this.disabledInnerDotColor,
  });

  final double size;
  final Color unselectedBorderColor;
  final Color unselectedDisabledBorderColor;
  final Color selectedFillColor;
  final Color selectedDisabledFillColor;
  final Color innerDotColor;
  final Color disabledInnerDotColor;
}

/// Figma `Controls / Radio Buttons` (`40:7530`) token resolver.
abstract final class RadioTokens {
  RadioTokens._();

  static const double size = 24;
  static const double innerDotRatio = 0.42;

  static RadioStyleSpec resolve({
    required AppColors colors,
    required Brightness brightness,
  }) {
    final dark = colors.palettes.dark;
    final isDark = brightness == Brightness.dark;

    return RadioStyleSpec(
      size: responsiveDimension(size),
      unselectedBorderColor: isDark ? dark.shade600 : dark.shade300,
      unselectedDisabledBorderColor: isDark ? dark.shade800 : dark.shade200,
      selectedFillColor: colors.primary,
      selectedDisabledFillColor: isDark ? dark.shade900 : dark.shade200,
      innerDotColor: colors.white,
      disabledInnerDotColor: isDark ? dark.shade800 : dark.shade200,
    );
  }

  static RadioThemeData radioTheme({
    required AppColors colors,
    required Brightness brightness,
  }) {
    final spec = resolve(colors: colors, brightness: brightness);

    return RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return states.contains(WidgetState.selected)
              ? spec.selectedDisabledFillColor
              : spec.unselectedDisabledBorderColor;
        }
        if (states.contains(WidgetState.selected)) {
          return spec.selectedFillColor;
        }
        return spec.unselectedBorderColor;
      }),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
