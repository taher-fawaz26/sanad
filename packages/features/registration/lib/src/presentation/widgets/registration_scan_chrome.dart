import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Dark-green → black diagonal gradient shared by the full-screen scan / capture
/// / extraction steps (matches [AuthScreenShell]'s header gradient and the Figma
/// scan frames). Centralised here so the colour lives in exactly one place.
const kRegistrationGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF10412F), Colors.black],
);

/// Full-screen gradient scaffold used by the scan-flow steps that have no white
/// content card (Review Photos, AI Extracting).
class RegistrationGradientScaffold extends StatelessWidget {
  const RegistrationGradientScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: kRegistrationGradient),
        child: SafeArea(child: child),
      ),
    );
  }
}

/// White back chevron aligned to the leading edge of the gradient scaffold.
class RegistrationScanBackButton extends StatelessWidget {
  const RegistrationScanBackButton({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsiveDimension(AppSpacing.xl),
        vertical: responsiveDimension(AppSpacing.md),
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: GestureDetector(
          onTap: onBack,
          behavior: HitTestBehavior.opaque,
          child: Icon(
            Icons.chevron_left,
            size: responsiveDimension(24),
            color: colors.white,
          ),
        ),
      ),
    );
  }
}

/// Centered white title + muted subtitle used on the gradient scan screens.
class RegistrationScanTitle extends StatelessWidget {
  const RegistrationScanTitle({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsiveDimension(AppSpacing.xl),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: typography.title3.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.white,
            ),
          ),
          SizedBox(height: responsiveDimension(AppSpacing.sm)),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: typography.smallNormal.copyWith(color: colors.gray200),
          ),
        ],
      ),
    );
  }
}

/// Two-step "Front Side / Back Side" indicator shown on the scan screens.
///
/// [activeStep] is 1-based (1 = front, 2 = back). Steps before [activeStep] are
/// rendered as completed; the current step is highlighted.
class ScanStepIndicator extends StatelessWidget {
  const ScanStepIndicator({
    required this.activeStep,
    required this.frontLabel,
    required this.backLabel,
    super.key,
  });

  final int activeStep;
  final String frontLabel;
  final String backLabel;

  static const double _stepSize = 40;
  static const double _connectorWidth = 91;
  static const double _connectorHeight = 4;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    Widget step({
      required int number,
      required String label,
      required bool active,
    }) {
      return Column(
        children: [
          Container(
            width: responsiveDimension(_stepSize),
            height: responsiveDimension(_stepSize),
            decoration: BoxDecoration(
              color: active ? colors.primary300 : colors.white,
              shape: BoxShape.circle,
              border: active ? null : Border.all(color: colors.border),
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: typography.smallNormal.copyWith(
                color: active ? colors.white : colors.textPrimary,
              ),
            ),
          ),
          SizedBox(height: responsiveDimension(AppSpacing.xs)),
          Text(
            label,
            style: typography.tinyNormal.copyWith(color: colors.white),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        step(number: 1, label: frontLabel, active: activeStep >= 1),
        Padding(
          padding: EdgeInsets.only(bottom: responsiveDimension(20)),
          child: Container(
            width: responsiveDimension(_connectorWidth),
            height: responsiveDimension(_connectorHeight),
            color: activeStep >= 2 ? colors.primary300 : colors.slate600,
          ),
        ),
        step(number: 2, label: backLabel, active: activeStep >= 2),
      ],
    );
  }
}
