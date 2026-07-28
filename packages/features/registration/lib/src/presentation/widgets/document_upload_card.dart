import 'package:app_assets/app_assets.dart';
import 'package:asset_picker/asset_picker.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:registration/src/presentation/widgets/captured_image.dart';

const _kDropzoneHeight = 136.0;
const _kUploadIconPlate = 40.0;
const _kCloudIconSize = 24.0;

/// A single document slot: title header, a dashed dropzone when empty or a
/// captured-document preview when filled, and an Upload / Change button.
///
/// Used by Identity Verification (Emirates ID front + back) and Trade Licence.
class DocumentUploadCard extends StatelessWidget {
  const DocumentUploadCard({
    required this.title,
    required this.onUpload,
    this.asset,
    super.key,
  });

  final String title;

  /// Opens the capture sheet. Same callback whether uploading or replacing.
  final VoidCallback onUpload;

  /// When non-null the card renders its filled state with a preview.
  final PickedAsset? asset;

  bool get _filled => asset != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

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
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: typography.smallNormal.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                if (_filled)
                  AppSvgPicture.asset(
                    AppSvgs.registrationCheckCircle,
                    width: responsiveDimension(20),
                    height: responsiveDimension(20),
                    colorFilter: ColorFilter.mode(
                      colors.success,
                      BlendMode.srcIn,
                    ),
                  ),
              ],
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
                if (_filled)
                  _FilledPreview(asset: asset!)
                else
                  const _EmptyDropzone(),
                SizedBox(height: responsiveDimension(AppSpacing.lg)),
                AppButton(
                  label: _filled
                      ? 'registration.change_doc'.tr()
                      : 'registration.upload'.tr(),
                  onPressed: onUpload,
                  type: _filled
                      ? AppButtonType.secondary
                      : AppButtonType.primary,
                  icon: AppSvgPicture.asset(
                    AppSvgs.cloudUpload,
                    width: responsiveDimension(ButtonTokens.iconSize),
                    height: responsiveDimension(ButtonTokens.iconSize),
                    colorFilter: ColorFilter.mode(
                      _filled ? colors.primary : colors.white,
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

class _EmptyDropzone extends StatelessWidget {
  const _EmptyDropzone();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final radius = AppRadius.md;

    return SizedBox(
      height: responsiveDimension(_kDropzoneHeight),
      width: double.infinity,
      child: CustomPaint(
        painter: DashedBorderPainter(color: colors.border, radius: radius),
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
              SizedBox(height: responsiveDimension(AppSpacing.md)),
              Text(
                'registration.choose_upload'.tr(),
                textAlign: TextAlign.center,
                style: typography.smallNormal.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
              SizedBox(height: responsiveDimension(AppSpacing.xs)),
              Text(
                'registration.choose_upload_hint'.tr(),
                textAlign: TextAlign.center,
                style: typography.tinyNormal.copyWith(color: colors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilledPreview extends StatelessWidget {
  const _FilledPreview({required this.asset});

  final PickedAsset asset;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final radius = AppRadius.md;
    final isImage = asset.mimeType.startsWith('image/');

    return SizedBox(
      height: responsiveDimension(_kDropzoneHeight),
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.gray50,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: colors.border),
          ),
          child: isImage
              ? CapturedImage(asset: asset)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: responsiveDimension(32),
                      color: colors.primary,
                    ),
                    SizedBox(height: responsiveDimension(AppSpacing.sm)),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsiveDimension(AppSpacing.md),
                      ),
                      child: Text(
                        asset.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: typography.smallNormal.copyWith(
                          color: colors.textPrimary,
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

/// Draws a rounded-rectangle dashed border (dash 6 / gap 4).
class DashedBorderPainter extends CustomPainter {
  DashedBorderPainter({required this.color, required this.radius});

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
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
