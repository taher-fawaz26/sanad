import 'package:asset_picker/asset_picker.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:localization/localization.dart';
import 'package:media_upload/media_upload.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/entities/provider_service_image_entity.dart';
import 'package:services/src/domain/usecases/add_provider_service_image_usecase.dart';
import 'package:services/src/domain/usecases/delete_provider_service_image_usecase.dart';
import 'package:services/src/domain/usecases/set_primary_provider_service_image_usecase.dart';
import 'package:services/src/presentation/widgets/service_confirmation_sheet.dart';
import 'package:services/src/presentation/widgets/service_image_card.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

const _maxImages = 6;

/// Live image lifecycle for an existing provider service — Service
/// Details' "Images" section.
///
/// Unlike the create-time [AddServiceImagesField] (which only stages
/// uploads locally until submit), every action here hits the backend
/// immediately: add via `POST /provider-services/:id/images`, set primary
/// via `PATCH .../images/:imageId/primary`, delete via
/// `DELETE .../images/:imageId`. `:imageId` is always the image row id
/// ([ProviderServiceImageEntity.id]), never the underlying `mediaId`.
class ManageServiceImagesSection extends StatefulWidget {
  const ManageServiceImagesSection({
    required this.service,
    required this.onServiceUpdated,
    super.key,
  });

  final ProviderServiceEntity service;

  /// Called with the refreshed service after any successful mutation.
  final ValueChanged<ProviderServiceEntity> onServiceUpdated;

  @override
  State<ManageServiceImagesSection> createState() =>
      _ManageServiceImagesSectionState();
}

class _ManageServiceImagesSectionState
    extends State<ManageServiceImagesSection> {
  bool _isAdding = false;
  String? _busyImageId;

  @override
  Widget build(BuildContext context) {
    final images = widget.service.images;
    final canAddMore = images.length < _maxImages && !_isAdding;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFieldLabel(
          label: 'services.images_count_label'.tr(
            namedArgs: {
              'count': images.length.toString(),
              'max': _maxImages.toString(),
            },
          ),
        ),
        SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final image in images)
              ServiceImageCard(
                key: ValueKey(image.id),
                data: MediaUploadTileData(
                  id: image.id,
                  previewUrl: image.url,
                  fileName: image.id,
                  progress: 1,
                  status: _busyImageId == image.id
                      ? MediaUploadTileStatus.uploading
                      : MediaUploadTileStatus.success,
                ),
                isMain: image.isPrimary,
                onMenuTap: _busyImageId != null
                    ? () {}
                    : () => _onImageMenu(image),
                onRetry: () {},
              ),
            if (canAddMore) ServiceImageAddCard(onTap: _pickAndAddImages),
          ],
        ),
      ],
    );
  }

  Future<void> _onImageMenu(ProviderServiceImageEntity image) async {
    final action = await SheetNavigator.push<_ImageMenuAction>(
      context,
      _ImageMenuSheet(isMain: image.isPrimary),
      settings: const SheetRouteSettings(
        sheetSize: SheetSize.expanded,
        padChild: false,
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _ImageMenuAction.setMain:
        await _setPrimary(image);
      case _ImageMenuAction.delete:
        await _deleteImage(image);
    }
  }

  Future<void> _setPrimary(ProviderServiceImageEntity image) async {
    setState(() => _busyImageId = image.id);
    final result = await sl<SetPrimaryProviderServiceImageUseCase>()(
      SetPrimaryProviderServiceImageParams(
        id: widget.service.id,
        imageId: image.id,
      ),
    ).run();
    if (!mounted) return;
    setState(() => _busyImageId = null);
    result.fold(_showFailure, widget.onServiceUpdated);
  }

  Future<void> _deleteImage(ProviderServiceImageEntity image) async {
    final confirmed = await showServiceConfirmationSheet(
      context: context,
      title: 'services.delete_image_confirm_title'.tr(),
      description: 'services.delete_image_confirm_description'.tr(),
      actionLabel: 'services.delete_image_confirm_action'.tr(),
      cancelLabel: 'services.cancel'.tr(),
      destructive: true,
    );
    if (!(confirmed ?? false) || !mounted) return;

    setState(() => _busyImageId = image.id);
    final result = await sl<DeleteProviderServiceImageUseCase>()(
      DeleteProviderServiceImageParams(id: widget.service.id, imageId: image.id),
    ).run();
    if (!mounted) return;
    setState(() => _busyImageId = null);
    result.fold(_showFailure, (_) {
      widget.onServiceUpdated(
        widget.service.copyWith(
          images: widget.service.images.where((i) => i.id != image.id).toList(),
        ),
      );
    });
  }

  Future<void> _pickAndAddImages() async {
    final remaining = _maxImages - widget.service.images.length;
    if (remaining <= 0) return;

    final result = await AssetPicker.pick(
      context,
      options: AssetPickerOptions(allowFiles: false, allowMultiple: remaining > 1),
    );
    if (!result.hasAssets || !mounted) return;

    setState(() => _isAdding = true);
    var current = widget.service;
    for (final asset in result.assets.take(remaining)) {
      final uploaded = await sl<MediaUploadRepository>()
          .upload(uploadKey: generateUuidV4(), asset: asset)
          .run();
      final failure = uploaded.fold((f) => f, (_) => null);
      if (failure != null) {
        if (mounted) _showFailure(failure);
        continue;
      }
      final mediaId = uploaded.fold((_) => null, (media) => media.mediaId)!;

      final added = await sl<AddProviderServiceImageUseCase>()(
        AddProviderServiceImageParams(id: current.id, mediaId: mediaId),
      ).run();
      added.fold(
        (f) {
          if (mounted) _showFailure(f);
        },
        (service) => current = service,
      );
    }
    if (!mounted) return;
    setState(() => _isAdding = false);
    widget.onServiceUpdated(current);
  }

  void _showFailure(Failure failure) {
    final display = failureErrorDisplay(failure);
    showAppSnackbar(
      context: context,
      title: display.title,
      caption: display.description,
      color: AppSnackbarColor.error,
      layout: AppSnackbarLayout.fullWidth,
    );
  }
}

enum _ImageMenuAction { setMain, delete }

/// Figma `5239:5772` — per-image "⋮" menu, reused from the create-time
/// images field.
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
        if (!isMain)
          _MenuRow(
            icon: Icons.star_border,
            label: 'services.image_menu_set_main'.tr(),
            color: colors.textPrimary,
            onTap: () => Navigator.of(context).pop(_ImageMenuAction.setMain),
          ),
        if (!isMain) const AppDivider(),
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
