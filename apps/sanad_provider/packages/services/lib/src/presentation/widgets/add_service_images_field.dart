import 'package:asset_picker/asset_picker.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_upload/media_upload.dart';
import 'package:services/src/presentation/models/service_image_tile.dart';
import 'package:services/src/presentation/widgets/service_images_editor.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// "Images" field of the Add Service / Request New Service forms — real
/// `media_upload` integration, no bespoke upload logic.
///
/// Renders the shared [ServiceImagesEditor] — [MediaUploadBloc] still owns
/// every upload/progress/retry/remove behaviour, this widget is
/// presentation only.
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
        final tileData = [
          for (final item in state.items)
            MediaUploadTileData(
              id: item.localId,
              previewUrl: item.url,
              fileName: item.fileName,
              progress: item.progress,
              status: _tileStatus(item.status),
              // `MediaUploadFailure.message` is always an i18n key, never
              // already-localized text — `MediaUploadTileData.errorMessage`
              // is rendered as-is (no `.tr()` downstream), so it must be
              // resolved here.
              errorMessage: item.failure?.message.tr(),
            ),
        ];
        final mainId = tileData.isEmpty
            ? null
            : tileData
                  .firstWhere(
                    (i) => i.status == MediaUploadTileStatus.success,
                    orElse: () => tileData.first,
                  )
                  .id;
        final items = [
          for (final data in tileData)
            ServiceImageTile(data: data, isMain: data.id == mainId),
        ];

        final maxFiles = state.config.maxFiles ?? 5;

        return ServiceImagesEditor(
          items: items,
          maxImages: maxFiles,
          label: 'services.add_service.images_label'.tr(),
          isRequired: true,
          onMenuTap: (id) => _onDeleteImage(context, id),
          onRetry: (id) => context.read<MediaUploadBloc>().add(
            MediaUploadRetryRequested(id),
          ),
          onAddTap: () => _pickImages(context),
        );
      },
    );
  }

  Future<void> _onDeleteImage(BuildContext context, String id) async {
    final confirmed = await showConfirmationSheet(
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
    final AssetPickerResult result;
    try {
      result = await AssetPicker.pick(
        context,
        options: AssetPickerOptions(
          allowFiles: false,
          allowMultiple: true,
          // Without this, `maxSelection` defaults to 1 and the gallery
          // provider silently truncates a multi-select down to the first
          // asset — bound it to the remaining slots instead so a batch
          // pick can never exceed `maxFiles` either.
          maxSelection: remaining,
          // Rejects an oversized file immediately — before it's returned
          // here, so no upload, progress, or `MediaUploadBloc` item is ever
          // created for it. `MediaUploadConfig.maxFileSize` (set on this
          // screen's bloc) is a second, defensive check for anything that
          // reaches it another way (e.g. `MediaUploadReplaceRequested`).
          maxFileSize: FileSizePolicy.maxBytes,
        ),
      );
    } on AssetValidationException catch (e) {
      if (context.mounted) _showValidationError(context, e);
      return;
    }
    if (!result.hasAssets || !context.mounted) return;
    bloc.add(MediaUploadAssetsAdded(result.assets));
  }

  void _showValidationError(BuildContext context, AssetValidationException e) {
    final isTooLarge = e.errors.any(
      (error) => error.type == AssetValidationErrorType.fileTooLarge,
    );
    showAppErrorSnackbar(
      context: context,
      title: isTooLarge
          ? 'errors.media_upload.file_too_large'.tr()
          : 'errors.media_upload.unsupported_type'.tr(),
    );
  }

  static MediaUploadTileStatus _tileStatus(MediaUploadStatus status) =>
      switch (status) {
        MediaUploadStatus.pending => MediaUploadTileStatus.pending,
        MediaUploadStatus.uploading => MediaUploadTileStatus.uploading,
        MediaUploadStatus.success => MediaUploadTileStatus.success,
        MediaUploadStatus.failure => MediaUploadTileStatus.failure,
      };
}
