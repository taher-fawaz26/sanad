import 'package:asset_picker/asset_picker.dart'
    show AssetValidationErrorType, AssetValidationException, PickedAsset;
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:media/src/actions_sheet/media_actions_sheet.dart';
import 'package:media/src/config/media_editor_config.dart';
import 'package:media/src/config/media_lifecycle_callbacks.dart';
import 'package:media/src/config/media_picker_config.dart';
import 'package:media/src/config/media_viewer_config.dart';
import 'package:media/src/editor/media_editor_page.dart';
import 'package:media/src/models/edited_media.dart';
import 'package:media/src/models/media_source.dart';
import 'package:media/src/picker/media_picker.dart';
import 'package:media/src/utilities/media_permissions.dart';
import 'package:media/src/validation/media_validator.dart';
import 'package:media/src/viewer/media_viewer_page.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// The outcome of a media flow. The package produces this and stops — the
/// consuming feature decides what to do next (upload, remove via its own
/// repository, etc.).
sealed class MediaFlowResult {
  const MediaFlowResult();
}

/// The user picked and edited a new image; [media] is ready to upload.
final class MediaEdited extends MediaFlowResult {
  const MediaEdited(this.media);
  final EditedMedia media;
}

/// The user confirmed they want the current media removed (the confirmation
/// dialog has already been shown and accepted).
final class MediaRemoveRequested extends MediaFlowResult {
  const MediaRemoveRequested();
}

/// The user opened the fullscreen viewer; nothing changed.
final class MediaViewed extends MediaFlowResult {
  const MediaViewed();
}

/// The flow ended without a result (dismissed, permission denied, validation
/// rejected, or edit cancelled).
final class MediaCancelled extends MediaFlowResult {
  const MediaCancelled();
}

/// Orchestrates the end-to-end media flow: action sheet → permission →
/// pick → validate → edit/process → [EditedMedia], plus view and
/// remove-with-confirmation.
///
/// This is the only place that ties `asset_picker`, `Navigator`, permissions,
/// and the editor together. It never uploads and never touches business
/// entities, endpoints, or network code.
abstract final class MediaCoordinator {
  MediaCoordinator._();

  static Future<MediaFlowResult> start(
    BuildContext context, {
    required String actionSheetTitle,
    MediaEditorConfig editorConfig = const MediaEditorConfig(),
    MediaPickerConfig pickerConfig = const MediaPickerConfig(),
    MediaViewerConfig viewerConfig = const MediaViewerConfig(),
    String? existingImageUrl,
    bool allowRemove = true,
    MediaLifecycleCallbacks? callbacks,
  }) async {
    final hasMedia = existingImageUrl != null && existingImageUrl.isNotEmpty;

    final action = await MediaActionsSheet.show(
      context,
      title: actionSheetTitle,
      hasMedia: hasMedia,
      allowRemove: allowRemove,
    );
    if (action == null || !context.mounted) return const MediaCancelled();

    switch (action) {
      case MediaAction.view:
        return _view(context, existingImageUrl!, viewerConfig, callbacks);
      case MediaAction.gallery:
        return _pickEdit(
          context,
          AssetSource.gallery,
          editorConfig,
          pickerConfig,
          callbacks,
        );
      case MediaAction.files:
        return _pickEdit(
          context,
          AssetSource.files,
          editorConfig,
          pickerConfig,
          callbacks,
        );
      case MediaAction.camera:
        return _pickEdit(
          context,
          AssetSource.camera,
          editorConfig,
          pickerConfig,
          callbacks,
        );
      case MediaAction.remove:
        return _remove(context);
    }
  }

  static Future<MediaFlowResult> _view(
    BuildContext context,
    String imageUrl,
    MediaViewerConfig viewerConfig,
    MediaLifecycleCallbacks? callbacks,
  ) async {
    callbacks?.onViewerOpened?.call();
    await Navigator.of(context).push(
      MediaViewerPage.route(imageUrl: imageUrl, config: viewerConfig),
    );
    callbacks?.onViewerClosed?.call();
    return const MediaViewed();
  }

  static Future<MediaFlowResult> _pickEdit(
    BuildContext context,
    MediaSource source,
    MediaEditorConfig editorConfig,
    MediaPickerConfig pickerConfig,
    MediaLifecycleCallbacks? callbacks,
  ) async {
    callbacks?.onEditStarted?.call();

    // Permission first (shared rationale + Open-Settings UX).
    final granted = await MediaPermissions.ensureFor(context, source);
    if (!granted || !context.mounted) {
      callbacks?.onEditCancelled?.call();
      return const MediaCancelled();
    }

    // Pick. `asset_picker`'s own validator (driven by `pickerConfig`'s
    // `maxFileSize`/extensions, via `toAssetPickerOptions()`) runs inside
    // this call and throws `AssetValidationException` on a rejected file —
    // surfaced here rather than swallowed as a cancellation, so an
    // oversized/unsupported pick shows the same feedback a user gets from
    // [MediaValidator]'s own (redundant, in-memory) check below.
    final PickedAsset? asset;
    try {
      asset = await _safePick(source, pickerConfig);
    } on AssetValidationException catch (e) {
      if (context.mounted) {
        final message =
            e.errors.any(
              (error) => error.type == AssetValidationErrorType.fileTooLarge,
            )
            ? 'errors.media_upload.file_too_large'.tr()
            : 'media.validation.unsupported_type'.tr();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
      callbacks?.onEditCancelled?.call();
      return const MediaCancelled();
    }
    if (asset == null) {
      callbacks?.onEditCancelled?.call();
      return const MediaCancelled();
    }

    // Validate before opening the editor.
    final error = MediaValidator.validate(asset, pickerConfig);
    if (error != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.messageKey.tr())),
        );
      }
      callbacks?.onEditCancelled?.call();
      return const MediaCancelled();
    }

    final bytes = asset.bytes;
    if (bytes == null || !context.mounted) {
      callbacks?.onEditCancelled?.call();
      return const MediaCancelled();
    }

    // Edit + process.
    final edited = await Navigator.of(context).push(
      MediaEditorPage.route(
        bytes: bytes,
        config: editorConfig,
        source: source,
        originalFileName: asset.name,
      ),
    );
    if (edited == null) {
      callbacks?.onEditCancelled?.call();
      return const MediaCancelled();
    }

    callbacks?.onEditCompleted?.call(edited);
    return MediaEdited(edited);
  }

  static Future<PickedAsset?> _safePick(
    MediaSource source,
    MediaPickerConfig config,
  ) async {
    try {
      return await MediaPicker.pick(source: source, config: config);
    } on AssetValidationException {
      // Rejected by `asset_picker`'s own validator — the caller must show
      // this, not swallow it (see `_pickEdit`'s catch).
      rethrow;
    } on Object {
      // Every other exception (permission / platform / source-unavailable)
      // → treat as cancellation; the permission gate already handled the
      // denied-permission UX, and there's nothing actionable to show for
      // an unexpected platform failure here.
      return null;
    }
  }

  static Future<MediaFlowResult> _remove(BuildContext context) async {
    final confirmed = await showConfirmationSheet(
      context: context,
      title: 'media.remove_confirm_title'.tr(),
      description: 'media.remove_confirm_message'.tr(),
      actionLabel: 'media.remove'.tr(),
      cancelLabel: 'common.cancel'.tr(),
      actionIntent: AppButtonIntent.destructive,
    );
    return (confirmed ?? false)
        ? const MediaRemoveRequested()
        : const MediaCancelled();
  }
}
