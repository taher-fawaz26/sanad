import 'dart:async';

import 'package:asset_picker/asset_picker.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization.dart';
import 'package:media_upload/media_upload.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/entities/provider_service_image_entity.dart';
import 'package:services/src/domain/usecases/add_provider_service_image_usecase.dart';
import 'package:services/src/domain/usecases/delete_provider_service_image_usecase.dart';
import 'package:services/src/domain/usecases/set_primary_provider_service_image_usecase.dart';
import 'package:services/src/presentation/widgets/service_image_card.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Maximum images a service may carry — matches the backend's "Image limit
/// of six reached" rule enforced by `POST .../images`.
const int kMaxServiceImages = 6;

/// Live image lifecycle for an existing provider service — mounted in Edit
/// Service, below the name/category/description fields.
///
/// Every action here hits the backend immediately (no staging, no
/// resubmission through `PATCH /provider-services/{id}`): add via
/// `POST /provider-services/:id/images`, set primary via
/// `PATCH .../images/:imageId/primary`, delete via
/// `DELETE .../images/:imageId`. `:imageId` is always the image row id
/// ([ProviderServiceImageEntity.id]), never the underlying `mediaId`
/// returned by the upload step.
///
/// New images are staged through the [MediaUploadBloc] already provided
/// above this widget (see `ServicesModule`'s `edit` route) exactly like
/// Add Service — upload success and attach success are tracked separately:
/// an uploaded item only leaves the "in progress" row once
/// [AddProviderServiceImageUseCase] confirms the attach. An attach failure
/// never re-triggers the (already-successful) upload; retrying it only
/// re-calls the attach.
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

enum _AttachStatus { attaching, failed }

class _ManageServiceImagesSectionState
    extends State<ManageServiceImagesSection> {
  String? _busyImageId;

  /// Attach phase for upload-succeeded items, keyed by
  /// [MediaUploadItem.localId].
  /// Absent once attached (the item is folded into `widget.service.images`
  /// and dropped from the in-progress row) or while the upload itself is
  /// still pending/uploading/failed.
  final Map<String, _AttachStatus> _attachStatus = {};

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return BlocConsumer<MediaUploadBloc, MediaUploadState>(
      listener: (context, state) => _onUploadStateChanged(state),
      builder: (context, uploadState) {
        final images = widget.service.images;
        final inProgress = uploadState.items.where(_isInProgress).toList();
        final remaining =
            kMaxServiceImages - images.length - inProgress.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'services.details.images'.tr(),
              style: typography
                  .medium(typography.smallNormal)
                  .copyWith(color: colors.textSecondary),
            ),
            SizedBox(height: AppSpacing.md),
            if (images.isNotEmpty) ...[
              Row(
                children: [
                  for (var i = 0; i < images.length; i++) ...[
                    if (i > 0) SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _ServiceImageThumbnail(
                        key: ValueKey(images[i].id),
                        imageUrl: images[i].url,
                        isBusy: _busyImageId == images[i].id,
                        onTap: _busyImageId != null
                            ? null
                            : () => _onImageMenu(images[i]),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: AppSpacing.md),
            ],
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final item in inProgress)
                  ServiceImageCard(
                    key: ValueKey(item.localId),
                    data: _tileData(item),
                    isMain: false,
                    onMenuTap: () => _onRemoveInProgress(item),
                    onRetry: () => _onRetry(item),
                  ),
                if (remaining > 0)
                  ServiceImageAddCard(
                    onTap: () => _pickImages(context, remaining),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  bool _isInProgress(MediaUploadItem item) {
    if (!item.isSuccess) return true;
    return _attachStatus.containsKey(item.localId);
  }

  MediaUploadTileData _tileData(MediaUploadItem item) {
    final attachStatus = _attachStatus[item.localId];
    final status = switch (item.status) {
      MediaUploadStatus.pending => MediaUploadTileStatus.pending,
      MediaUploadStatus.uploading => MediaUploadTileStatus.uploading,
      MediaUploadStatus.failure => MediaUploadTileStatus.failure,
      MediaUploadStatus.success => switch (attachStatus) {
        _AttachStatus.failed => MediaUploadTileStatus.failure,
        _AttachStatus.attaching || null => MediaUploadTileStatus.success,
      },
    };
    return MediaUploadTileData(
      id: item.localId,
      previewUrl: item.url,
      fileName: item.fileName,
      progress: item.progress,
      status: status,
      errorMessage: item.failure?.message,
    );
  }

  Future<void> _pickImages(BuildContext context, int remaining) async {
    if (!CollectionSizeValidator.isValid(1, maxItems: remaining)) {
      _showLimitReached();
      return;
    }
    final result = await AssetPicker.pick(
      context,
      options: AssetPickerOptions(
        allowFiles: false,
        allowMultiple: true,
        maxSelection: remaining,
      ),
    );
    if (!result.hasAssets || !mounted) return;
    context.read<MediaUploadBloc>().add(
      MediaUploadAssetsAdded(result.assets),
    );
  }

  void _showLimitReached() {
    showAppSnackbar(
      context: context,
      title: 'services.image_limit_reached'.tr(
        namedArgs: {'max': kMaxServiceImages.toString()},
      ),
      color: AppSnackbarColor.error,
      layout: AppSnackbarLayout.fullWidth,
    );
  }

  void _onUploadStateChanged(MediaUploadState state) {
    final newlySucceeded = [
      for (final item in state.items)
        if (item.isSuccess &&
            item.mediaId != null &&
            !_attachStatus.containsKey(item.localId))
          item,
    ];
    if (newlySucceeded.isEmpty) return;

    setState(() {
      for (final item in newlySucceeded) {
        _attachStatus[item.localId] = _AttachStatus.attaching;
      }
    });
    for (final item in newlySucceeded) {
      unawaited(_attachImage(item.localId, item.mediaId!));
    }
  }

  Future<void> _attachImage(String localId, String mediaId) async {
    final result = await sl<AddProviderServiceImageUseCase>()(
      AddProviderServiceImageParams(id: widget.service.id, mediaId: mediaId),
    ).run();
    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() => _attachStatus[localId] = _AttachStatus.failed);
        _showFailure(failure);
      },
      (updated) {
        // Deliberately does NOT dispatch `MediaUploadRemoveRequested` here
        // — that best-effort deletes the underlying media for locally
        // picked items, which would delete the file this attach call just
        // referenced. Dropping `localId` from `_attachStatus` is enough:
        // `_isInProgress` then treats it as done and hides it from the
        // in-progress row, while the bloc item itself is left alone.
        setState(() => _attachStatus.remove(localId));
        widget.onServiceUpdated(updated);
      },
    );
  }

  void _onRetry(MediaUploadItem item) {
    if (_attachStatus[item.localId] == _AttachStatus.failed) {
      setState(() => _attachStatus[item.localId] = _AttachStatus.attaching);
      unawaited(_attachImage(item.localId, item.mediaId!));
      return;
    }
    context.read<MediaUploadBloc>().add(
      MediaUploadRetryRequested(item.localId),
    );
  }

  Future<void> _onRemoveInProgress(MediaUploadItem item) async {
    if (_attachStatus[item.localId] == _AttachStatus.attaching) return;
    final confirmed = await showConfirmationSheet(
      context: context,
      title: 'services.delete_image_confirm_title'.tr(),
      description: 'services.delete_image_confirm_description'.tr(),
      actionLabel: 'services.delete_image_confirm_action'.tr(),
      cancelLabel: 'common.cancel'.tr(),
      destructive: true,
    );
    if (!(confirmed ?? false) || !mounted) return;
    setState(() => _attachStatus.remove(item.localId));
    context.read<MediaUploadBloc>().add(
      MediaUploadRemoveRequested(item.localId),
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
    final confirmed = await showConfirmationSheet(
      context: context,
      title: 'services.delete_image_confirm_title'.tr(),
      description: 'services.delete_image_confirm_description'.tr(),
      actionLabel: 'services.delete_image_confirm_action'.tr(),
      cancelLabel: 'common.cancel'.tr(),
      destructive: true,
    );
    if (!(confirmed ?? false) || !mounted) return;

    setState(() => _busyImageId = image.id);
    final result = await sl<DeleteProviderServiceImageUseCase>()(
      DeleteProviderServiceImageParams(
        id: widget.service.id,
        imageId: image.id,
      ),
    ).run();
    if (!mounted) return;
    setState(() => _busyImageId = null);
    result.fold(_showFailure, widget.onServiceUpdated);
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

/// Figma `4715:26510` — equal `flex-1` thumbnails, `80px` tall, `6px`
/// radius. Tapping opens [_ImageMenuSheet] (set main / delete).
class _ServiceImageThumbnail extends StatelessWidget {
  const _ServiceImageThumbnail({
    required this.imageUrl,
    required this.isBusy,
    required this.onTap,
    super.key,
  });

  final String imageUrl;
  final bool isBusy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppDimension.radiusSm);

    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: SizedBox(
        height: responsiveDimension(80),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppNetworkImage(imageUrl, borderRadius: radius),
            if (isBusy)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: radius,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
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
          label: 'common.delete'.tr(),
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
