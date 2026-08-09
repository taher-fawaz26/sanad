import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Visual state of a [MediaUploadDropZone].
enum MediaUploadDropZoneState { idle, loading, success, error }

/// Single upload-card / drop-zone: shows an upload icon, size/format hints,
/// and switches its content for the loading/success/error states. Reuses the
/// same status vocabulary as `MediaUploadGrid` but for a single file.
class MediaUploadDropZone extends StatelessWidget {
  const MediaUploadDropZone({
    super.key,
    this.state = MediaUploadDropZoneState.idle,
    this.progress = 0.0,
    this.maxFileSizeLabel,
    this.acceptedFormatsLabel,
    this.errorMessage,
    this.previewUrl,
    this.onAdd,
    this.onRetry,
  });

  final MediaUploadDropZoneState state;
  final double progress;
  final String? maxFileSizeLabel;
  final String? acceptedFormatsLabel;
  final String? errorMessage;
  final String? previewUrl;

  final VoidCallback? onAdd;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return InkWell(
      onTap: switch (state) {
        MediaUploadDropZoneState.idle => onAdd,
        MediaUploadDropZoneState.error => onRetry,
        _ => null,
      },
      borderRadius: BorderRadius.circular(AppDimension.radiusMd),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          border: Border.all(
            color: state == MediaUploadDropZoneState.error
                ? colors.palettes.red.shade500
                : colors.border,
          ),
          borderRadius: BorderRadius.circular(AppDimension.radiusMd),
        ),
        child: _content(context),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    switch (state) {
      case MediaUploadDropZoneState.loading:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLoadingIndicator(size: 32),
            SizedBox(height: AppSpacing.sm),
            AppProgressBar(value: progress),
            SizedBox(height: AppSpacing.xs),
            Text(
              '${(progress * 100).round()}%',
              style: typography.smallNormal.copyWith(color: colors.textMuted),
            ),
          ],
        );
      case MediaUploadDropZoneState.success:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: colors.success, size: 32),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Uploaded',
              style: typography.smallNormal.copyWith(color: colors.textPrimary),
            ),
          ],
        );
      case MediaUploadDropZoneState.error:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: colors.palettes.red.shade500,
              size: 32,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              errorMessage ?? 'Upload failed. Tap to retry.',
              textAlign: TextAlign.center,
              style: typography.smallNormal.copyWith(
                color: colors.palettes.red.shade500,
              ),
            ),
          ],
        );
      case MediaUploadDropZoneState.idle:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              color: colors.textSecondary,
              size: 32,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Tap to upload',
              style: typography.smallNormal.copyWith(color: colors.textPrimary),
            ),
            if (maxFileSizeLabel != null || acceptedFormatsLabel != null) ...[
              SizedBox(height: AppSpacing.xs),
              Text(
                [
                  acceptedFormatsLabel,
                  maxFileSizeLabel,
                ].whereType<String>().join(' · '),
                textAlign: TextAlign.center,
                style: typography.smallNormal.copyWith(
                  color: colors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        );
    }
  }
}
