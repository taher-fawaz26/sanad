import 'package:app_assets/app_assets.dart';
import 'package:asset_picker/asset_picker.dart';
import 'package:design_system/design_system.dart';
import 'package:document_flow/src/presentation/widgets/document_preview.dart';
import 'package:flutter/material.dart';

const _kDropzoneHeight = 136.0;
const _kUploadIconPlate = 40.0;
const _kCloudIconSize = 24.0;
const _kCancelSize = 32.0;
const _kCancelIconSize = 20.0;
const _kLoaderSize = 14.0;

/// Every user-facing label [DocumentUploadCard] needs, resolved by the
/// feature so the widget itself carries no l10n keys.
class DocumentUploadCardLabels {
  const DocumentUploadCardLabels({
    required this.chooseUpload,
    required this.chooseUploadHint,
    required this.uploading,
    required this.uploadFailed,
    required this.replaceDocument,
    required this.removeDocument,
    required this.upload,
    required this.retryUpload,
  });

  final String chooseUpload;
  final String chooseUploadHint;
  final String uploading;
  final String uploadFailed;
  final String replaceDocument;
  final String removeDocument;
  final String upload;
  final String retryUpload;
}

/// A single document slot: title header, empty / uploading / filled / failed
/// body, and an Upload / Change / Retry button.
///
/// Upload lifecycle is carried exclusively by [UploadableAsset].
class DocumentUploadCard extends StatelessWidget {
  const DocumentUploadCard({
    required this.title,
    required this.onUpload,
    required this.labels,
    this.uploadable,
    this.onCancel,
    this.onRemove,
    this.onReplace,
    super.key,
  });

  final String title;

  /// Opens the capture sheet (or retries after failure).
  final VoidCallback onUpload;

  final DocumentUploadCardLabels labels;

  /// When non-null the card renders uploading / filled / failed from this.
  final UploadableAsset? uploadable;

  /// Cancels the in-flight HTTP upload. Required while [uploadable] is
  /// uploading.
  final VoidCallback? onCancel;

  /// Clears a locally captured (pending) document.
  final VoidCallback? onRemove;

  /// Re-picks a locally captured document via the capture flow.
  final VoidCallback? onReplace;

  bool get _hasLocalAsset => uploadable?.asset != null;

  bool get _uploaded => uploadable?.isUploaded ?? false;

  bool get _uploading => uploadable?.isUploading ?? false;

  bool get _failed => uploadable?.status.isFailed ?? false;

  bool get _localPending =>
      _hasLocalAsset && !_uploaded && !_uploading && !_failed;

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
                if (_uploaded)
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
                if (_uploading && uploadable != null)
                  _UploadingDropzone(
                    uploadable: uploadable!,
                    uploadingLabel: labels.uploading,
                    onCancel: onCancel,
                  )
                else if (_failed && uploadable != null)
                  _FailedDropzone(
                    uploadable: uploadable!,
                    uploadFailedLabel: labels.uploadFailed,
                  )
                else if (_hasLocalAsset && uploadable != null)
                  _FilledPreview(asset: uploadable!.asset)
                else
                  _EmptyDropzone(
                    chooseUploadLabel: labels.chooseUpload,
                    chooseUploadHintLabel: labels.chooseUploadHint,
                  ),
                SizedBox(height: responsiveDimension(AppSpacing.lg)),
                if (_localPending || _uploaded) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _CardActionButton(
                          label: labels.replaceDocument,
                          icon: AppSvgs.registrationReplace,
                          color: colors.primary,
                          onPressed: onReplace ?? onUpload,
                        ),
                      ),
                      SizedBox(width: responsiveDimension(AppSpacing.lg)),
                      Expanded(
                        child: _CardActionButton(
                          label: labels.removeDocument,
                          icon: AppSvgs.registrationRemove,
                          color: colors.error,
                          onPressed: onRemove,
                        ),
                      ),
                    ],
                  ),
                ] else
                  AppButton(
                    label: _failed ? labels.retryUpload : labels.upload,
                    onPressed: _uploading ? null : onUpload,
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

class _EmptyDropzone extends StatelessWidget {
  const _EmptyDropzone({
    required this.chooseUploadLabel,
    required this.chooseUploadHintLabel,
  });

  final String chooseUploadLabel;
  final String chooseUploadHintLabel;

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
                chooseUploadLabel,
                textAlign: TextAlign.center,
                style: typography.smallNormal.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
              SizedBox(height: responsiveDimension(AppSpacing.xs)),
              Text(
                chooseUploadHintLabel,
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

class _UploadingDropzone extends StatelessWidget {
  const _UploadingDropzone({
    required this.uploadable,
    required this.uploadingLabel,
    this.onCancel,
  });

  final UploadableAsset uploadable;
  final String uploadingLabel;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final radius = AppRadius.md;
    final asset = uploadable.asset;
    final percent = (uploadable.progress * 100).round().clamp(0, 100);

    return SizedBox(
      width: double.infinity,
      child: CustomPaint(
        painter: DashedBorderPainter(color: colors.border, radius: radius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.gray50,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: responsiveDimension(AppSpacing.lg),
              vertical: responsiveDimension(AppSpacing.xxl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            asset.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: typography.regularNormal.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          SizedBox(height: responsiveDimension(AppSpacing.md)),
                          Text(
                            _formatMeta(asset),
                            style: typography.tinyNormal.copyWith(
                              fontWeight: FontWeight.w500,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onCancel != null)
                      GestureDetector(
                        onTap: onCancel,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: responsiveDimension(_kCancelSize),
                          height: responsiveDimension(_kCancelSize),
                          decoration: BoxDecoration(
                            color: colors.slate100,
                            borderRadius: BorderRadius.circular(
                              responsiveDimension(16),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: AppSvgPicture.asset(
                            AppSvgs.close,
                            width: responsiveDimension(_kCancelIconSize),
                            height: responsiveDimension(_kCancelIconSize),
                            colorFilter: ColorFilter.mode(
                              colors.textPrimary,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: responsiveDimension(AppSpacing.lg)),
                Row(
                  children: [
                    Expanded(
                      child: AppProgressBar(value: uploadable.progress),
                    ),
                    SizedBox(width: responsiveDimension(AppSpacing.lg)),
                    SizedBox(
                      width: responsiveDimension(40),
                      child: Text(
                        '$percent%',
                        style: typography.tinyNormal.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: responsiveDimension(AppSpacing.md)),
                Row(
                  children: [
                    SizedBox(
                      width: responsiveDimension(_kLoaderSize),
                      height: responsiveDimension(_kLoaderSize),
                      child: const AppLoadingIndicator(size: _kLoaderSize),
                    ),
                    SizedBox(width: responsiveDimension(AppSpacing.sm)),
                    Text(
                      uploadingLabel,
                      style: typography.tinyNormal.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatMeta(PickedAsset asset) {
    final sizeLabel = asset.sizeInMb >= 0.1
        ? '${asset.sizeInMb.toStringAsFixed(1)} MB'
        : '${asset.sizeInKb.toStringAsFixed(0)} KB';
    final typeLabel = asset.extension.isNotEmpty
        ? asset.extension.toUpperCase()
        : asset.mimeType;
    return '$sizeLabel  •  $typeLabel';
  }
}

class _FailedDropzone extends StatelessWidget {
  const _FailedDropzone({
    required this.uploadable,
    required this.uploadFailedLabel,
  });

  final UploadableAsset uploadable;
  final String uploadFailedLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final radius = AppRadius.md;

    return SizedBox(
      height: responsiveDimension(_kDropzoneHeight),
      width: double.infinity,
      child: CustomPaint(
        painter: DashedBorderPainter(color: colors.error, radius: radius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.gray50,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                uploadable.asset.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: typography.smallNormal.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: responsiveDimension(AppSpacing.sm)),
              Text(
                uploadFailedLabel,
                textAlign: TextAlign.center,
                style: typography.tinyNormal.copyWith(color: colors.error),
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.gray50,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(responsiveDimension(AppSpacing.lg)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: SizedBox(
                height: responsiveDimension(148),
                child: isImage
                    ? DocumentPreview(asset: asset)
                    : ColoredBox(
                        color: colors.gray100,
                        child: Center(
                          child: Icon(
                            Icons.description_outlined,
                            size: responsiveDimension(32),
                            color: colors.primary,
                          ),
                        ),
                      ),
              ),
            ),
            SizedBox(height: responsiveDimension(AppSpacing.lg)),
            Text(
              asset.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typography.smallNormal.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: responsiveDimension(AppSpacing.xs)),
            Text(
              _formatSize(asset),
              style: typography.tinyNormal.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatSize(PickedAsset asset) {
    if (asset.sizeInMb >= 1.0) {
      return '${asset.sizeInMb.toStringAsFixed(1)} MB';
    }
    return '${asset.sizeInKb.toStringAsFixed(0)} KB';
  }
}

/// Outlined action button used in the Replace / Remove row.
class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final String icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsiveDimension(48)),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: responsiveDimension(AppSpacing.lg),
          vertical: responsiveDimension(AppSpacing.sm),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: context.appTypography.smallNormal.copyWith(
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
          SizedBox(width: responsiveDimension(AppSpacing.sm)),
          AppSvgPicture.asset(
            icon,
            width: responsiveDimension(18),
            height: responsiveDimension(18),
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
        ],
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
