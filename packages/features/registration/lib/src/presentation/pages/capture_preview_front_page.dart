import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _kGradientStart = Color(0xFF10412F);
const _kPreviewHeight = 220.0;
const _kStepSize = 40.0;
const _kConnectorWidth = 91.0;
const _kConnectorHeight = 4.0;
const _kCardAspectWidth = 254.76;
const _kCardAspectHeight = 156.49;

/// Step 8 — Preview of captured Emirates ID front side.
///
/// Figma: `capturing` (`2897:13610`).
///
/// Full-screen gradient scaffold (not [AuthScreenShell]) — same chrome as the
/// scan flow frames.
class CapturePreviewFrontPage extends StatelessWidget {
  const CapturePreviewFrontPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kGradientStart, Colors.black],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsiveDimension(AppSpacing.xl),
                  vertical: responsiveDimension(AppSpacing.md),
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Icon(
                      Icons.chevron_left,
                      size: responsiveDimension(24),
                      color: colors.white,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsiveDimension(AppSpacing.xl),
                ),
                child: Column(
                  children: [
                    Text(
                      'Scan Emirates ID',
                      textAlign: TextAlign.center,
                      style: typography.title3.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.white,
                      ),
                    ),
                    SizedBox(height: responsiveDimension(AppSpacing.sm)),
                    Text(
                      'Place the front inside the frame',
                      textAlign: TextAlign.center,
                      style: typography.smallNormal.copyWith(
                        color: colors.gray200,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: responsiveDimension(AppSpacing.md)),
              const _ScanStepIndicator(activeStep: 1),
              const Spacer(),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsiveDimension(AppSpacing.xl),
                ),
                child: const _CapturePreview(),
              ),
              const Spacer(),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  responsiveDimension(AppSpacing.xl),
                  0,
                  responsiveDimension(AppSpacing.xl),
                  responsiveDimension(AppSpacing.xl),
                ),
                child: Column(
                  children: [
                    AppButtonPresets.primary(
                      label: 'Scan Back Side',
                      onPressed: () {
                        // Scan Emirates ID back — next screen.
                      },
                      icon: Transform.flip(
                        flipX: true,
                        child: AppSvgPicture.asset(
                          AppSvgs.registrationArrowRight,
                          width: responsiveDimension(ButtonTokens.iconSize),
                          height: responsiveDimension(ButtonTokens.iconSize),
                          colorFilter: ColorFilter.mode(
                            colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      iconPosition: AppButtonIconPosition.right,
                    ),
                    SizedBox(height: responsiveDimension(AppSpacing.md)),
                    AppButtonPresets.secondary(
                      label: 'Retake Front Side',
                      onPressed: () => context.pop(),
                      icon: AppSvgPicture.asset(
                        AppSvgs.registrationRetake,
                        width: responsiveDimension(ButtonTokens.iconSize),
                        height: responsiveDimension(ButtonTokens.iconSize),
                        colorFilter: ColorFilter.mode(
                          colors.primary300,
                          BlendMode.srcIn,
                        ),
                      ),
                      iconPosition: AppButtonIconPosition.right,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanStepIndicator extends StatelessWidget {
  const _ScanStepIndicator({required this.activeStep});

  final int activeStep;

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
            width: responsiveDimension(_kStepSize),
            height: responsiveDimension(_kStepSize),
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
        step(number: 1, label: 'Front Side', active: activeStep == 1),
        Padding(
          padding: EdgeInsets.only(bottom: responsiveDimension(20)),
          child: Container(
            width: responsiveDimension(_kConnectorWidth),
            height: responsiveDimension(_kConnectorHeight),
            color: colors.slate600,
          ),
        ),
        step(number: 2, label: 'Back Side', active: activeStep == 2),
      ],
    );
  }
}

class _CapturePreview extends StatelessWidget {
  const _CapturePreview();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      height: responsiveDimension(_kPreviewHeight),
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.black.withValues(alpha: 0.25),
        ),
        child: Center(
          child: AspectRatio(
            aspectRatio: _kCardAspectWidth / _kCardAspectHeight,
            child: ClipRRect(
              borderRadius: AppRadius.circularMd,
              child: Image.asset(
                AppImages.emiratesIdFrontPreview,
                package: AppAssets.package,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
