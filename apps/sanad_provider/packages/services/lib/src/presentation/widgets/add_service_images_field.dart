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
/// matches Figma `5261:44387`/`5222:44137` exactly (filename caption, inline
/// status row, "Main" badge, "⋮" menu) — [MediaUploadBloc] still owns every
/// upload/progress/retry/remove behaviour, this widget is presentation only.
/// The empty state is a dashed "Upload a photos" drop zone.
///
/// Per-image "⋮" menu (Figma `5239:5772`, Set as main image / Delete):
/// `MediaUploadTileData` has no persisted "main image" concept and the real
/// `CreateServiceParams`/`mediaIds` submission has no primary-image field
/// either, so "main image" is tracked as UI-only local state (defaults to
/// the first successfully-uploaded image, matching the Figma reference)
/// and nothing is persisted on submit (see audit blockers).
///
/// The empty state (`_ImagesDropZone`) is a plain bordered "Add Image" tile
/// matching Figma `4715:24468`, not a dashed drop zone.
class AddServiceImagesField extends StatefulWidget {
  /// Creates the Images field. Expects a `MediaUploadBloc` above it in the
  /// widget tree (see `AddServicePage`'s `BlocProvider`).
  const AddServiceImagesField({super.key});

  @override
  State<AddServiceImagesField> createState() => _AddServiceImagesFieldState();
}

class _AddServiceImagesFieldState extends State<AddServiceImagesField> {
  String? _mainImageId;

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
    final mainId =
        _mainImageId ??
        items
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
            onMenuTap: () => _onImageMenu(context, item.id),
            onRetry: () => context.read<MediaUploadBloc>().add(
              MediaUploadRetryRequested(item.id),
            ),
          ),
        if (canAddMore) ServiceImageAddCard(onTap: () => _pickImages(context)),
      ],
    );
  }

  Future<void> _onImageMenu(BuildContext context, String id) async {
    final action = await SheetNavigator.push<_ImageMenuAction>(
      context,
      _ImageMenuSheet(isMain: _mainImageId == id),
      settings: const SheetRouteSettings(
        sheetSize: SheetSize.expanded,
        padChild: false,
      ),
    );

    if (!context.mounted || action == null) return;
    switch (action) {
      case _ImageMenuAction.setMain:
        setState(() => _mainImageId = id);
      case _ImageMenuAction.delete:
        await _onDeleteImage(context, id);
    }
  }

  Future<void> _onDeleteImage(BuildContext context, String id) async {
    final confirmed = await showServiceConfirmationSheet(
      context: context,
      title: 'services.delete_image_confirm_title'.tr(),
      description: 'services.delete_image_confirm_description'.tr(),
      actionLabel: 'services.delete_image_confirm_action'.tr(),
      cancelLabel: 'services.cancel'.tr(),
      destructive: true,
    );
    if ((confirmed ?? false) && context.mounted) {
      context.read<MediaUploadBloc>().add(MediaUploadRemoveRequested(id));
      if (_mainImageId == id) setState(() => _mainImageId = null);
    }
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

enum _ImageMenuAction { setMain, delete }

/// Figma `5239:5772` — per-image "⋮" menu.
class _ImageMenuSheet extends StatelessWidget {
  const _ImageMenuSheet({required this.isMain});

  final bool isMain;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: AppSpacing.lg),
        _MenuRow(
          icon: isMain ? Icons.star : Icons.star_border,
          label: 'services.image_menu_set_main'.tr(),
          color: colors.textPrimary,
          onTap: () => Navigator.of(context).pop(_ImageMenuAction.setMain),
        ),
        const AppDivider(),
        _MenuRow(
          icon: Icons.delete_outline,
          label: 'services.image_menu_delete'.tr(),
          color: colors.error,
          onTap: () => Navigator.of(context).pop(_ImageMenuAction.delete),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Material(
      color: colors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: [
              Icon(icon, size: 24, color: color),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  label,
                  style: typography.regularNormal.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
