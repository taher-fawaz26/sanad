import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/wizard_step_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma wizard step indicator — `_Partials / Date` (`194:4474`).
///
/// Numbered circles connected by thin dividers. [currentStep] is 1-based.
class AppWizardStepIndicator extends StatelessWidget {
  const AppWizardStepIndicator({
    required this.currentStep,
    required this.totalSteps,
    super.key,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final brightness = Theme.of(context).brightness;
    final spec = WizardStepTokens.resolve(
      colors: colors,
      typography: typography,
      brightness: brightness,
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          for (var step = 1; step <= totalSteps; step++) ...[
            if (step > 1)
              Expanded(
                child: Container(
                  height: spec.connectorHeight,
                  // Completed segments stay primary (Figma `347:13772` / `972:9206`).
                  color: step <= currentStep
                      ? spec.activeBackground
                      : spec.connectorColor,
                ),
              ),
            _StepDot(
              step: step,
              // Past and current steps are filled; upcoming stay inactive.
              isActive: step <= currentStep,
              spec: spec,
            ),
          ],
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.step,
    required this.isActive,
    required this.spec,
  });

  final int step;
  final bool isActive;
  final WizardStepStyleSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: spec.stepSize,
      height: spec.stepSize,
      decoration: BoxDecoration(
        color: isActive ? spec.activeBackground : spec.inactiveBackground,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$step',
        style: spec.stepLabelStyle.copyWith(
          color: isActive ? spec.activeForeground : spec.inactiveForeground,
        ),
      ),
    );
  }
}
