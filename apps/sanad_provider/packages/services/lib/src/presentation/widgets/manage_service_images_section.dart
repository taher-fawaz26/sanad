import 'package:asset_picker/asset_picker.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization.dart';
import 'package:media_upload/media_upload.dart';
import 'package:services/src/domain/constants/service_image_limits.dart';
import 'package:services/src/domain/entities/provider_service_image_entity.dart';
import 'package:services/src/presentation/bloc/service_images/service_images_bloc.dart';
import 'package:services/src/presentation/models/service_image_tile.dart';
import 'package:services/src/presentation/widgets/service_images_editor.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Live image lifecycle for an existing provider service — mounted in Edit
/// Service, below the name/category/description fields.
///
/// Purely presentational: renders [ServiceImagesBloc] state through the
/// shared [ServiceImagesEditor] (same component Add Service uses) and
/// dispatches events. Requires a [ServiceImagesBloc] and a `MediaUploadBloc`
/// already provided above it (see `ServicesModule`'s `edit` route) —
/// new-image uploads are staged through the latter exactly like Add
/// Service, and this widget forwards its state into [ServiceImagesBloc]
/// verbatim ([ServiceImagesUploadStateChanged]); the bloc alone decides
/// which items are newly-succeeded and kicks off their attach.
class ManageServiceImagesSection extends StatelessWidget {
  const ManageServiceImagesSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Outer `BlocConsumer<MediaUploadBloc>` both forwards its state into
    // `ServiceImagesBloc` (listener) AND hands its already-subscribed state
    // down to the inner builder as a plain value — deliberately NOT a
    // second, independent `context.watch<MediaUploadBloc>()` call nested
    // inside `ServiceImagesBloc`'s own builder, to keep the two blocs'
    // rebuild triggers structurally separate.
    return BlocConsumer<MediaUploadBloc, MediaUploadState>(
      listener: (context, uploadState) => context
          .read<ServiceImagesBloc>()
          .add(ServiceImagesUploadStateChanged(uploadState.items)),
      builder: (context, uploadState) {
        return BlocConsumer<ServiceImagesBloc, ServiceImagesState>(
          listenWhen: (previous, current) =>
              current.failureNonce != previous.failureNonce,
          listener: _showFailure,
          builder: (context, state) {
            final images = state.service.images;
            final inProgress = uploadState.items
                .where((item) => _isInProgress(item, state))
                .toList();
            final remaining =
                kMaxServiceImages - images.length - inProgress.length;

            // Committed images first (backend array order, never
            // re-sorted — "Main" is a per-tile flag, not a position), then
            // in-progress uploads appended after.
            final items = [
              for (final image in images)
                ServiceImageTile(
                  data: MediaUploadTileData(
                    id: image.id,
                    previewUrl: image.url,
                    status: MediaUploadTileStatus.success,
                  ),
                  // Backend truth, never positional — this is the fix: a
                  // committed image's "Main" badge must reflect
                  // `isPrimary`, not array position.
                  isMain: image.isPrimary,
                  isBusy: state.busyImageId == image.id,
                ),
              for (final item in inProgress)
                ServiceImageTile(
                  data: _tileData(item, state),
                  isMain: false,
                ),
            ];
            final committedById = {
              for (final image in images) image.id: image,
            };
            final inProgressById = {
              for (final item in inProgress) item.localId: item,
            };

            return ServiceImagesEditor(
              items: items,
              maxImages: kMaxServiceImages,
              label: 'services.details.images'.tr(),
              onMenuTap: (id) => _onMenuTap(
                context,
                state,
                id,
                committedById,
                inProgressById,
              ),
              onRetry: (id) {
                final item = inProgressById[id];
                if (item != null) _onRetry(context, item, state);
              },
              onAddTap: () => _pickImages(context, remaining),
            );
          },
        );
      },
    );
  }

  void _onMenuTap(
    BuildContext context,
    ServiceImagesState state,
    String id,
    Map<String, ProviderServiceImageEntity> committedById,
    Map<String, MediaUploadItem> inProgressById,
  ) {
    // Any image mid-mutation blocks every row's menu, not just the busy
    // one — matches the prior single-row-at-a-time gate.
    if (state.busyImageId != null) return;
    final committed = committedById[id];
    if (committed != null) {
      _onImageMenu(context, committed);
      return;
    }
    final item = inProgressById[id];
    if (item != null) _onRemoveInProgress(context, item);
  }

  bool _isInProgress(MediaUploadItem item, ServiceImagesState state) {
    if (!item.isSuccess) return true;
    return state.attachStatus.containsKey(item.localId);
  }

  MediaUploadTileData _tileData(
    MediaUploadItem item,
    ServiceImagesState state,
  ) {
    final attachStatus = state.attachStatus[item.localId];
    final status = switch (item.status) {
      MediaUploadStatus.pending => MediaUploadTileStatus.pending,
      MediaUploadStatus.uploading => MediaUploadTileStatus.uploading,
      MediaUploadStatus.failure => MediaUploadTileStatus.failure,
      MediaUploadStatus.success => switch (attachStatus) {
        ServiceImagesAttachStatus.failed => MediaUploadTileStatus.failure,
        ServiceImagesAttachStatus.attaching ||
        null => MediaUploadTileStatus.success,
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
      _showLimitReached(context);
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
    if (!result.hasAssets || !context.mounted) return;
    context.read<MediaUploadBloc>().add(
      MediaUploadAssetsAdded(result.assets),
    );
  }

  void _showLimitReached(BuildContext context) {
    showAppSnackbar(
      context: context,
      title: 'services.image_limit_reached'.tr(
        namedArgs: {'max': kMaxServiceImages.toString()},
      ),
      color: AppSnackbarColor.error,
      layout: AppSnackbarLayout.fullWidth,
    );
  }

  void _onRetry(
    BuildContext context,
    MediaUploadItem item,
    ServiceImagesState state,
  ) {
    if (state.attachStatus[item.localId] == ServiceImagesAttachStatus.failed) {
      context.read<ServiceImagesBloc>().add(
        ServiceImagesAttachRetryRequested(
          localId: item.localId,
          mediaId: item.mediaId!,
        ),
      );
      return;
    }
    context.read<MediaUploadBloc>().add(
      MediaUploadRetryRequested(item.localId),
    );
  }

  Future<void> _onRemoveInProgress(
    BuildContext context,
    MediaUploadItem item,
  ) async {
    final isAttaching =
        context.read<ServiceImagesBloc>().state.attachStatus[item.localId] ==
        ServiceImagesAttachStatus.attaching;
    if (isAttaching) return;

    final confirmed = await showConfirmationSheet(
      context: context,
      title: 'services.delete_image_confirm_title'.tr(),
      description: 'services.delete_image_confirm_description'.tr(),
      actionLabel: 'services.delete_image_confirm_action'.tr(),
      cancelLabel: 'common.cancel'.tr(),
      destructive: true,
    );
    if (!(confirmed ?? false) || !context.mounted) return;

    context.read<ServiceImagesBloc>().add(
      ServiceImagesInProgressRemoved(item.localId),
    );
    context.read<MediaUploadBloc>().add(
      MediaUploadRemoveRequested(item.localId),
    );
  }

  Future<void> _onImageMenu(
    BuildContext context,
    ProviderServiceImageEntity image,
  ) async {
    final action = await SheetNavigator.push<_ImageMenuAction>(
      context,
      _ImageMenuSheet(isMain: image.isPrimary),
      settings: const SheetRouteSettings(
        sheetSize: SheetSize.expanded,
        padChild: false,
      ),
    );
    if (!context.mounted || action == null) return;
    switch (action) {
      case _ImageMenuAction.setMain:
        context.read<ServiceImagesBloc>().add(
          ServiceImagesSetPrimaryRequested(image.id),
        );
      case _ImageMenuAction.delete:
        await _deleteImage(context, image);
    }
  }

  Future<void> _deleteImage(
    BuildContext context,
    ProviderServiceImageEntity image,
  ) async {
    final confirmed = await showConfirmationSheet(
      context: context,
      title: 'services.delete_image_confirm_title'.tr(),
      description: 'services.delete_image_confirm_description'.tr(),
      actionLabel: 'services.delete_image_confirm_action'.tr(),
      cancelLabel: 'common.cancel'.tr(),
      destructive: true,
    );
    if (!(confirmed ?? false) || !context.mounted) return;

    context.read<ServiceImagesBloc>().add(
      ServiceImagesDeleteRequested(image.id),
    );
  }

  void _showFailure(BuildContext context, ServiceImagesState state) {
    final display = failureErrorDisplay(state.mutationFailure);
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
