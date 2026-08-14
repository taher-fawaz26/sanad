import 'package:asset_picker/asset_picker.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_upload/media_upload.dart';
import 'package:services/src/presentation/widgets/service_confirmation_sheet.dart';
import 'package:services/src/presentation/widgets/service_image_card.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// "Images" field of the Add Service / Request New Service forms — real
/// `media_upload` integration, no bespoke upload logic.
///
/// Renders a Services-specific 2-column card grid ([ServiceImageCard]) that
/// matches Figma `5261:44387`/`5222:44137` (filename caption, inline status
/// row, "Main" badge, "⋮" menu) — [MediaUploadBloc] still owns every
/// upload/progress/retry/remove behaviour, this widget is presentation only.
///
/// The first successfully-uploaded image is shown with the "Main" badge —
/// this mirrors the real backend rule (`POST /provider-services`: the
/// first entry in `imageIds` becomes primary), so there is no separate
/// "set main" action here; upload order is the only control. Service
/// Details only previews images read-only (`ServiceImagesPreview`) —
/// there is currently no UI to add/delete/re-order images once a service
/// exists.
class AddServiceImagesField extends StatefulWidget {
  /// Creates the Images field. Expects a `MediaUploadBloc` above it in the
  /// widget tree (see `AddServicePage`'s `BlocProvider`).
  const AddServiceImagesField({super.key});

  @override
  State<AddServiceImagesField> createState() => _AddServiceImagesFieldState();
}

class _AddServiceImagesFieldState extends State<AddServiceImagesField> {
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

        final maxFiles = state.config.maxFiles ?? 5;
        final isEmpty = items.isEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: AppFieldLabel(
                    label: isEmpty
                        ? 'services.add_service.images_label'.tr()
                        : 'services.images_count_label'.tr(
                            namedArgs: {
                              'count': items.length.toString(),
                              'max': maxFiles.toString(),
                            },
                          ),
                    isRequired: isEmpty,
                  ),
                ),
                Flexible(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.appColors.palettes.sky.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        'services.images_max_badge'.tr(
                          namedArgs: {'max': maxFiles.toString()},
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.appTypography.tinyNormal.copyWith(
                          color: context.appColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            if (isEmpty)
              _ImagesDropZone(onTap: () => _pickImages(context))
            else
              _buildGrid(context, items, maxFiles),
          ],
        );
      },
    );
  }

  Widget _buildGrid(
    BuildContext context,
    List<MediaUploadTileData> items,
    int maxFiles,
  ) {
    final mainId = items
        .firstWhere(
          (i) => i.status == MediaUploadTileStatus.success,
          orElse: () => items.first,
        )
        .id;
    final canAddMore = items.length < maxFiles;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final item in items)
          ServiceImageCard(
            key: ValueKey(item.id),
            data: item,
            isMain: item.id == mainId,
            onMenuTap: () => _onDeleteImage(context, item.id),
            onRetry: () => context.read<MediaUploadBloc>().add(
              MediaUploadRetryRequested(item.id),
            ),
          ),
        if (canAddMore) ServiceImageAddCard(onTap: () => _pickImages(context)),
      ],
    );
  }

  Future<void> _onDeleteImage(BuildContext context, String id) async {
    final confirmed = await showServiceConfirmationSheet(
      context: context,
      title: 'services.delete_image_confirm_title'.tr(),
      description: 'services.delete_image_confirm_description'.tr(),
      actionLabel: 'services.delete_image_confirm_action'.tr(),
      cancelLabel: 'common.cancel'.tr(),
      destructive: true,
    );
    if ((confirmed ?? false) && context.mounted) {
      context.read<MediaUploadBloc>().add(MediaUploadRemoveRequested(id));
    }
  }

  Future<void> _pickImages(BuildContext context) async {
    final bloc = context.read<MediaUploadBloc>();
    final maxFiles = bloc.state.config.maxFiles ?? 5;
    final remaining = maxFiles - bloc.state.items.length;
    if (remaining <= 0) return;
    final result = await AssetPicker.pick(
      context,
      options: AssetPickerOptions(
        allowFiles: false,
        allowMultiple: true,
        // Without this, `maxSelection` defaults to 1 and the gallery
        // provider silently truncates a multi-select down to the first
        // asset — bound it to the remaining slots instead so a batch pick
        // can never exceed `maxFiles` either.
        maxSelection: remaining,
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
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxl,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFBFC),
          borderRadius: BorderRadius.circular(AppDimension.radiusMd),
          border: Border.all(color: const Color(0xFFEAECF0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 24, color: colors.primary),
            SizedBox(height: AppSpacing.sm),
            Text(
              'services.add_service.images_add_label'.tr(),
              style: typography.regularNormal.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'services.add_service.images_max_size_caption'.tr(),
              textAlign: TextAlign.center,
              style: typography.smallNormal.copyWith(color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
