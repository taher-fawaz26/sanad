import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Resolved styling for [AppWizardStepIndicator].
@immutable
class WizardStepStyleSpec {
  const WizardStepStyleSpec({
    required this.stepSize,
    required this.connectorHeight,
    required this.activeBackground,
    required this.activeForeground,
    required this.inactiveBackground,
    required this.inactiveForeground,
    required this.connectorColor,
    required this.stepLabelStyle,
  });

  final double stepSize;
  final double connectorHeight;
  final Color activeBackground;
  final Color activeForeground;
  final Color inactiveBackground;
  final Color inactiveForeground;
  final Color connectorColor;
  final TextStyle stepLabelStyle;
}

/// Figma `_Partials / Date` wizard step (`194:4474`) token resolver.
abstract final class WizardStepTokens {
  WizardStepTokens._();

  static const double stepSize = 40;
  static const double connectorHeight = 4;

  static WizardStepStyleSpec resolve({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    final main = colors.palettes.main;
    final sky = colors.palettes.sky;
    final isDark = brightness == Brightness.dark;

    return WizardStepStyleSpec(
      stepSize: responsiveDimension(stepSize),
      connectorHeight: responsiveDimension(connectorHeight),
      activeBackground: colors.primary,
      activeForeground: colors.onPrimary,
      inactiveBackground: isDark ? sky.shade800 : sky.shade100,
      inactiveForeground: colors.textPrimary,
      connectorColor: isDark ? sky.shade700 : sky.shade200,
      stepLabelStyle: typography.smallNormal.copyWith(
        fontSize: 14,
        height: 14 / 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
    );
  }
}
