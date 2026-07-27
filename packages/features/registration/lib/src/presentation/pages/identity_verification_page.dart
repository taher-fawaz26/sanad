import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:registration/src/presentation/widgets/registration_header.dart';
import 'package:registration/src/presentation/widgets/select_capture_method_sheet.dart';
import 'package:registration/src/routes/registration_routes.dart';

const _kIconSize = 48.0;
const _kDropzoneHeight = 136.0;
const _kUploadIconPlate = 40.0;
const _kCloudIconSize = 24.0;

/// Step 5 — Emirates ID front/back upload (empty state).
///
/// Figma: `Identity Verification` (`2794:34425`).
class IdentityVerificationPage extends StatelessWidget {
  const IdentityVerificationPage({super.key});

  Future<void> _onUploadPressed(BuildContext context) {
    return showSelectCaptureMethodSheet(
      context: context,
      onSelected: (method) {
        switch (method) {
          case RegistrationCaptureMethod.scanOrCapture:
            context.push(RegistrationRoutes.scanEmiratesIdFront);
          case RegistrationCaptureMethod.uploadFile:
          case RegistrationCaptureMethod.gallery:
            // File / gallery pick — next screens.
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSvgPicture.asset(
          AppSvgs.registrationIdentityScan,
          width: responsiveDimension(_kIconSize),
          height: responsiveDimension(_kIconSize),
          colorFilter: ColorFilter.mode(
            colors.textPrimary,
            BlendMode.srcIn,
          ),
        ),
        SizedBox(height: responsiveDimension(AppSpacing.xxxl)),
        const RegistrationHeader(
          title: 'Identity Verification',
          subtitle: Text(
            'Upload your Emirates ID to verify your identity and complete '
            'registration.',
          ),
        ),
        SizedBox(height: responsiveDimension(AppSpacing.xxxl)),
        _DocumentUploadCard(
          title: '1. Emirates ID Front Side',
          onUpload: () => _onUploadPressed(context),
        ),
        SizedBox(height: responsiveDimension(AppSpacing.xxxl)),
        _DocumentUploadCard(
          title: '2. Emirates ID Back side',
          onUpload: () => _onUploadPressed(context),
        ),
        SizedBox(height: responsiveDimension(AppSpacing.xxxl)),
        const AppButton(
          label: 'Continue',
          onPressed: null,
        ),
      ],
    );
  }
}

/// Local empty-state upload card — kept private until reused on another screen.
class _DocumentUploadCard extends StatelessWidget {
  const _DocumentUploadCard({
    required this.title,
    required this.onUpload,
  });

  final String title;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final radius = AppRadius.md;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimension.radiusProfileCard),
        border: Border.all(color: colors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: responsiveDimension(AppSpacing.xxl),
              vertical: responsiveDimension(AppSpacing.sm),
            ),
            child: Text(
              title,
              style: typography.smallNormal.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          Divider(height: 1, thickness: 1, color: colors.gray100),
          Padding(
            padding: EdgeInsets.fromLTRB(
              responsiveDimension(AppSpacing.xxl),
              responsiveDimension(AppSpacing.lg),
              responsiveDimension(AppSpacing.xxl),
              responsiveDimension(AppSpacing.xxl),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: responsiveDimension(_kDropzoneHeight),
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _DashedBorderPainter(
                      color: colors.border,
                      radius: radius,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.gray50,
                        borderRadius: BorderRadius.circular(radius),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: responsiveDimension(_kUploadIconPlate),
                            height: responsiveDimension(_kUploadIconPlate),
                            decoration: BoxDecoration(
                              color: colors.primary50,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: AppSvgPicture.asset(
                              AppSvgs.cloudUpload,
                              width: responsiveDimension(_kCloudIconSize),
                              height: responsiveDimension(_kCloudIconSize),
                              colorFilter: ColorFilter.mode(
                                colors.primary,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: responsiveDimension(AppSpacing.md),
                          ),
                          Text(
                            'Choose how to upload your document',
                            textAlign: TextAlign.center,
                            style: typography.smallNormal.copyWith(
                              fontWeight: FontWeight.w500,
                              color: colors.textSecondary,
                            ),
                          ),
                          SizedBox(
                            height: responsiveDimension(AppSpacing.xs),
                          ),
                          Text(
                            'Capture, Scan, or select from Gallery',
                            textAlign: TextAlign.center,
                            style: typography.tinyNormal.copyWith(
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: responsiveDimension(AppSpacing.lg)),
                AppButton(
                  label: 'Upload',
                  onPressed: onUpload,
                  icon: AppSvgPicture.asset(
                    AppSvgs.cloudUpload,
                    width: responsiveDimension(ButtonTokens.iconSize),
                    height: responsiveDimension(ButtonTokens.iconSize),
                    colorFilter: ColorFilter.mode(
                      colors.white,
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
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
          Radius.circular(radius),
        ),
      );

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
