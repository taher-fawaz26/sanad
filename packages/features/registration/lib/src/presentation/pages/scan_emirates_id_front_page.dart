import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:registration/src/routes/registration_routes.dart';

const _kGradientStart = Color(0xFF10412F);
const _kViewfinderHeight = 220.0;
const _kCornerLength = 16.0;
const _kCornerThickness = 3.0;
const _kStepSize = 40.0;
const _kShutterSize = 77.0;
const _kConnectorWidth = 91.0;
const _kConnectorHeight = 4.0;

/// Step 7 — Scan Emirates ID front side (camera UI chrome only).
///
/// Figma: `capturing front` (`2897:13536`).
///
/// Full-screen gradient scaffold (not [AuthScreenShell]) — matches the scan
/// flow frames which have no white content card.
class ScanEmiratesIdFrontPage extends StatelessWidget {
  const ScanEmiratesIdFrontPage({super.key});

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
              SizedBox(height: responsiveDimension(AppSpacing.xxl)),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsiveDimension(AppSpacing.xl),
                ),
                child: const _Viewfinder(),
              ),
              const Spacer(),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  responsiveDimension(AppSpacing.xxl),
                  0,
                  responsiveDimension(AppSpacing.xxl),
                  responsiveDimension(AppSpacing.xl),
                ),
                child: SizedBox(
                  height: responsiveDimension(_kShutterSize),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: GestureDetector(
                          onTap: () {
                            // Gallery pick — next screens.
                          },
                          child: AppSvgPicture.asset(
                            AppSvgs.registrationGallery,
                            width: responsiveDimension(24),
                            height: responsiveDimension(24),
                            colorFilter: ColorFilter.mode(
                              colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          context.push(RegistrationRoutes.capturePreviewFront);
                        },
                        child: AppSvgPicture.asset(
                          AppSvgs.registrationShutter,
                          width: responsiveDimension(_kShutterSize),
                          height: responsiveDimension(_kShutterSize),
                        ),
                      ),
                    ],
                  ),
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
              border: active
                  ? null
                  : Border.all(color: colors.border),
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

class _Viewfinder extends StatelessWidget {
  const _Viewfinder();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final corner = responsiveDimension(_kCornerLength);
    final thickness = responsiveDimension(_kCornerThickness);

    Widget cornerBracket({
      required Alignment alignment,
    }) {
      final isLeft = alignment == Alignment.topLeft ||
          alignment == Alignment.bottomLeft;
      final isTop = alignment == Alignment.topLeft ||
          alignment == Alignment.topRight;

      return Align(
        alignment: alignment,
        child: SizedBox(
          width: corner,
          height: corner,
          child: Stack(
            children: [
              Positioned(
                left: isLeft ? 0 : null,
                right: isLeft ? null : 0,
                top: isTop ? 0 : null,
                bottom: isTop ? null : 0,
                child: Container(
                  width: corner,
                  height: thickness,
                  color: colors.white,
                ),
              ),
              Positioned(
                left: isLeft ? 0 : null,
                right: isLeft ? null : 0,
                top: isTop ? 0 : null,
                bottom: isTop ? null : 0,
                child: Container(
                  width: thickness,
                  height: corner,
                  color: colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: responsiveDimension(_kViewfinderHeight),
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.black.withValues(alpha: 0.25),
        ),
        child: Padding(
          padding: EdgeInsets.all(responsiveDimension(AppSpacing.md)),
          child: Stack(
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: 254.76 / 156.49,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.black.withValues(alpha: 0.35),
                      borderRadius: AppRadius.circularMd,
                    ),
                  ),
                ),
              ),
              cornerBracket(alignment: Alignment.topLeft),
              cornerBracket(alignment: Alignment.topRight),
              cornerBracket(alignment: Alignment.bottomLeft),
              cornerBracket(alignment: Alignment.bottomRight),
            ],
          ),
        ),
      ),
    );
  }
}
