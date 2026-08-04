import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:media/src/models/media_source.dart';
import 'package:permissions/permissions.dart';

/// Ensures the OS permission required for [source] is granted, running the
/// shared rationale + Open-Settings UX from the `permissions` package.
///
/// Returns `true` when access is usable. `files` needs no runtime permission
/// (document picker), so it always returns `true`.
abstract final class MediaPermissions {
  MediaPermissions._();

  static Future<bool> ensureFor(
    BuildContext context,
    MediaSource source,
  ) async {
    switch (source) {
      case AssetSource.camera:
      case AssetSource.scanner:
        final result = await Permissions.ensure(
          PermissionType.camera,
          context: context,
          explanation: PermissionExplanation(
            title: 'permissions.camera_title'.tr(),
            description: 'permissions.camera_description'.tr(),
            icon: PermissionIcons().forType(PermissionType.camera),
            allowLabel: 'permissions.allow'.tr(),
            denyLabel: 'permissions.deny'.tr(),
            openSettingsLabel: 'permissions.open_settings'.tr(),
            cancelLabel: 'permissions.cancel'.tr(),
          ),
        );
        return result.isGranted;
      case AssetSource.gallery:
        final result = await Permissions.ensure(
          PermissionType.gallery,
          context: context,
          explanation: PermissionExplanation(
            title: 'permissions.gallery_title'.tr(),
            description: 'permissions.gallery_description'.tr(),
            icon: PermissionIcons().forType(PermissionType.gallery),
            allowLabel: 'permissions.allow'.tr(),
            denyLabel: 'permissions.deny'.tr(),
            openSettingsLabel: 'permissions.open_settings'.tr(),
            cancelLabel: 'permissions.cancel'.tr(),
          ),
        );
        return result.isGranted;
      case AssetSource.files:
        return true;
    }
  }
}
