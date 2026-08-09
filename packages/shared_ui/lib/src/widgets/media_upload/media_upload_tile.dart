import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/src/widgets/media_upload/media_upload_tile_data.dart';

/// A single square upload tile — visualises
/// [MediaUploadTileData.status] (pending/uploading/success/failure) with a
/// preview, progress, and contextual actions.
///
/// Purely presentational: every action is a callback the owning feature wires
/// to its `MediaUploadBloc`. No network/upload logic lives here.
class MediaUploadTile extends StatelessWidget {
  const MediaUploadTile({
    required this.data,
    super.key,
    this.size = 96,
    this.onPreview,
    this.onReplace,
    this.onRemove,
    this.onRetry,
  });

  final MediaUploadTileData data;
  final double size;

  final VoidCallback? onPreview;
  final VoidCallback? onReplace;
  final VoidCallback? onRemove;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: data.status == MediaUploadTileStatus.success
                ? onPreview
                : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimension.radiusMd),
              child: ColoredBox(
                color: colors.disabled,
                child: _Preview(data: data),
              ),
            ),
          ),
          if (data.status == MediaUploadTileStatus.uploading)
            _UploadingOverlay(progress: data.progress),
          if (data.status == MediaUploadTileStatus.success)
            const _SuccessBadge(),
          if (data.status == MediaUploadTileStatus.failure)
            _FailureOverlay(
              errorMessage: data.errorMessage,
              onRetry: onRetry,
            ),
          if (onRemove != null)
            Positioned(
              top: 2,
              right: 2,
              child: AppIconButton(
                icon: Icons.close,
                onTap: onRemove,
                semanticLabel: 'Remove',
              ),
            ),
          if (onReplace != null && data.status == MediaUploadTileStatus.success)
            Positioned(
              bottom: 2,
              right: 2,
              child: AppIconButton(
                icon: Icons.edit_outlined,
                onTap: onReplace,
                semanticLabel: 'Replace',
              ),
            ),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.data});

  final MediaUploadTileData data;

  @override
  Widget build(BuildContext context) {
    final url = data.previewUrl;
    if (url != null && url.isNotEmpty) {
      return AppNetworkImage(url);
    }
    return Center(
      child: Icon(
        Icons.insert_drive_file_outlined,
        color: context.appColors.textSecondary,
      ),
    );
  }
}

class _UploadingOverlay extends StatelessWidget {
  const _UploadingOverlay({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45)),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLoadingIndicator(size: 28),
              SizedBox(height: AppSpacing.xs),
              Text(
                '${(progress * 100).round()}%',
                style: context.appTypography.smallNormal.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 4,
      left: 4,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: context.appColors.success,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 12, color: Colors.white),
      ),
    );
  }
}

class _FailureOverlay extends StatelessWidget {
  const _FailureOverlay({this.errorMessage, this.onRetry});

  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55)),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: context.appColors.palettes.red.shade500,
              ),
              if (errorMessage != null) ...[
                SizedBox(height: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: context.appTypography.smallNormal.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
              if (onRetry != null) ...[
                SizedBox(height: AppSpacing.xs),
                InkWell(
                  onTap: onRetry,
                  child: const Icon(
                    Icons.refresh,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
