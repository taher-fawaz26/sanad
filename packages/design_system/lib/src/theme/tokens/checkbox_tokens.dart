import 'package:design_system/design_system.dart' show AppCheckbox;
import 'package:design_system/src/components/app_checkbox.dart'
    show AppCheckbox;
import 'package:design_system/src/components/components.dart' show AppCheckbox;
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:flutter/material.dart';

/// Resolved styling for [AppCheckbox].
@immutable
class CheckboxStyleSpec {
  const CheckboxStyleSpec({
    required this.size,
    required this.borderRadius,
    required this.borderWidth,
    required this.unselectedBorderColor,
    required this.unselectedDisabledBorderColor,
    required this.selectedFillColor,
    required this.selectedDisabledFillColor,
    required this.checkColor,
    required this.disabledCheckColor,
  });

  final double size;
  final BorderRadius borderRadius;
  final double borderWidth;
  final Color unselectedBorderColor;
  final Color unselectedDisabledBorderColor;
  final Color selectedFillColor;
  final Color selectedDisabledFillColor;
  final Color checkColor;
  final Color disabledCheckColor;
}

/// Figma `Controls / Checkboxes` (`40:7543`) token resolver.
abstract final class CheckboxTokens {
  CheckboxTokens._();

  static const double size = 24;
  static const double borderRadius = 4;
  static const double borderWidth = 1;

  static CheckboxStyleSpec resolve({
    required AppColors colors,
    required Brightness brightness,
  }) {
    final dark = colors.palettes.dark;
    final isDark = brightness == Brightness.dark;

    return CheckboxStyleSpec(
      size: responsiveDimension(size),
      borderRadius: BorderRadius.circular(responsiveDimension(borderRadius)),
      borderWidth: borderWidth,
      unselectedBorderColor: isDark ? dark.shade600 : dark.shade300,
      unselectedDisabledBorderColor: isDark ? dark.shade800 : dark.shade200,
      selectedFillColor: colors.primary,
      selectedDisabledFillColor: isDark ? dark.shade900 : dark.shade200,
      checkColor: colors.white,
      disabledCheckColor: isDark ? dark.shade800 : dark.shade200,
    );
  }

  static CheckboxThemeData checkboxTheme({
    required AppColors colors,
    required Brightness brightness,
  }) {
    final spec = resolve(colors: colors, brightness: brightness);

    return CheckboxThemeData(
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: spec.borderRadius,
        side: BorderSide(
          color: spec.unselectedBorderColor,
          width: spec.borderWidth,
        ),
      ),
      side: BorderSide(
        color: spec.unselectedBorderColor,
        width: spec.borderWidth,
      ),
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return states.contains(WidgetState.selected)
              ? spec.selectedDisabledFillColor
              : Colors.transparent;
        }
        if (states.contains(WidgetState.selected)) {
          return spec.selectedFillColor;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return spec.disabledCheckColor;
        }
        return spec.checkColor;
      }),
    );
  }
}
