import 'package:app_assets/app_assets.dart';
import 'package:asset_picker/asset_picker.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_upload/media_upload.dart';
import 'package:shared_ui/shared_ui.dart';

/// "Images" field of the Add Service form — real `media_upload` integration,
/// no bespoke picker/upload code.
///
/// Renders [MediaUploadGrid] driven by [MediaUploadBloc]; the empty state is
/// swapped for a dashed "Upload a photos" drop zone matching the design
/// reference via [MediaUploadGrid.emptyStateBuilder] — the grid/bloc still
/// own every upload/progress/retry/remove behaviour.
class AddServiceImagesField extends StatelessWidget {
  /// Creates the Images field. Expects a `MediaUploadBloc` above it in the
  /// widget tree (see `AddServicePage`'s `BlocProvider`).
  const AddServiceImagesField({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaUploadBloc, MediaUploadState>(
      builder: (context, state) {
        final items = [
          for (final item in state.items)
            MediaUploadTileData(
              id: item.localId,
              previewUrl: item.url,
              fileName: item.fileName,
              progress: item.progress,
              status: _tileStatus(item.status),
              errorMessage: item.failure?.message,
            ),
        ];

        return MediaUploadGrid(
          items: items,
          maxFiles: state.config.maxFiles,
          addLabel: 'services.add_service.images_add_label'.tr(),
          emptyStateLabel: 'services.add_service.images_upload_label'.tr(),
          emptyStateBuilder: (context) => _ImagesDropZone(
            onTap: () => _pickImages(context),
          ),
          onAdd: () => _pickImages(context),
          onRetry: (id) => context.read<MediaUploadBloc>().add(
            MediaUploadRetryRequested(id),
          ),
          onRemove: (id) => context.read<MediaUploadBloc>().add(
            MediaUploadRemoveRequested(id),
          ),
          onRetryAll: () => context.read<MediaUploadBloc>().add(
            const MediaUploadRetryAllRequested(),
          ),
        );
      },
    );
  }

  Future<void> _pickImages(BuildContext context) async {
    final bloc = context.read<MediaUploadBloc>();
    final result = await AssetPicker.pick(
      context,
      options: const AssetPickerOptions(
        allowFiles: false,
        allowMultiple: true,
      ),
    );
    if (!result.hasAssets) return;
    bloc.add(MediaUploadAssetsAdded(result.assets));
  }

  static MediaUploadTileStatus _tileStatus(MediaUploadStatus status) =>
      switch (status) {
        MediaUploadStatus.pending => MediaUploadTileStatus.pending,
        MediaUploadStatus.uploading => MediaUploadTileStatus.uploading,
        MediaUploadStatus.success => MediaUploadTileStatus.success,
        MediaUploadStatus.failure => MediaUploadTileStatus.failure,
      };
}

class _ImagesDropZone extends StatelessWidget {
  const _ImagesDropZone({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimension.radiusMd),
      child: AppDashedBorder(
        color: colors.border,
        radius: AppDimension.radiusMd,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: responsiveDimension(48),
                height: responsiveDimension(48),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: AppSvgPicture.asset(
                    AppSvgs.cloudUpload,
                    width: responsiveDimension(24),
                    height: responsiveDimension(24),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                'services.add_service.images_upload_label'.tr(),
                style: typography.regularNormal.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                'services.add_service.images_max_size_caption'.tr(),
                style: typography.smallNormal.copyWith(color: colors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
