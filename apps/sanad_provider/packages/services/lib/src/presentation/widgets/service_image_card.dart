import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

/// Per-image card for the Add/Request-New-Service image grids — Figma
/// `5261:44387`'s `card-cover`/`card-uploading`/`card-failed` states
/// (`153×135`, 2-per-row). Services-specific presentation wrapping
/// [MediaUploadTileData] — carries no upload/business logic of its own, only
/// visuals `MediaUploadTile` (the generic shared tile) doesn't reproduce:
/// filename caption, inline status row, and the "Main" badge / "⋮" menu.
class ServiceImageCard extends StatelessWidget {
  const ServiceImageCard({
    required this.data,
    required this.isMain,
    required this.onMenuTap,
    super.key,
    this.onRetry,
    this.size = 153,
  });

  final MediaUploadTileData data;
  final bool isMain;
  final VoidCallback onMenuTap;
  final VoidCallback? onRetry;
  final double size;

  static const _successBg = Color(0xFFECFDF3);
  static const _successText = Color(0xFF027A48);
  static const _failedText = Color(0xFFFF5666);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: responsiveDimension(size),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimension.radiusMd),
        border: Border.all(color: colors.palettes.sky.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: responsiveDimension(72),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: colors.disabled,
                  child: data.previewUrl != null && data.previewUrl!.isNotEmpty
                      ? AppNetworkImage(data.previewUrl!)
                      : Icon(
                          Icons.insert_drive_file_outlined,
                          color: colors.textSecondary,
                        ),
                ),
                if (isMain)
                  PositionedDirectional(
                    top: AppSpacing.sm,
                    start: AppSpacing.sm,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(
                          AppDimension.radiusPill,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        child: Text(
                          'services.images_main_badge'.tr(),
                          style: context.appTypography.tinyNormal.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                PositionedDirectional(
                  top: AppSpacing.sm,
                  end: AppSpacing.sm,
                  child: GestureDetector(
                    onTap: onMenuTap,
                    child: Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.more_vert,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.fileName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.appTypography.tinyNormal.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                _buildStatus(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatus(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    switch (data.status) {
      case MediaUploadTileStatus.success:
        return DecoratedBox(
          decoration: BoxDecoration(
            color: _successBg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            child: Text(
              'services.images_uploaded_success'.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typography.tinyNormal.copyWith(
                color: _successText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      case MediaUploadTileStatus.uploading:
      case MediaUploadTileStatus.pending:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: data.progress,
                minHeight: 4,
                backgroundColor: colors.palettes.sky.shade200,
                color: colors.primary,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(data.progress * 100).round()}%',
                  style: typography.tinyNormal.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'services.images_uploading'.tr(),
                  style: typography.tinyNormal.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        );
      case MediaUploadTileStatus.failure:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: _failedText.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                child: Text(
                  'services.images_failed'.tr(),
                  style: typography.tinyNormal.copyWith(
                    color: _failedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: onRetry,
              child: Text(
                'services.images_retry'.tr(),
                style: typography.tinyNormal.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        );
    }
  }
}

/// Figma `add-thumbnail-button` grid variant (`5261:44463`) — a same-size
/// tile alongside existing images, no subtitle (unlike the large empty
/// dropzone).
class ServiceImageAddCard extends StatelessWidget {
  const ServiceImageAddCard({required this.onTap, super.key, this.size = 153});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimension.radiusMd),
      child: Container(
        width: responsiveDimension(size),
        height: responsiveDimension(size),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFBFC),
          borderRadius: BorderRadius.circular(AppDimension.radiusMd),
          border: Border.all(color: const Color(0xFFEAECF0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 24, color: colors.primary),
            SizedBox(height: AppSpacing.xs),
            Text(
              'services.add_service.images_add_label'.tr(),
              style: typography.smallNormal.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
