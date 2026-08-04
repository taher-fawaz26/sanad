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
        final result = await Permissions.ensureCamera(context: context);
        return result.isGranted;
      case AssetSource.gallery:
        final result = await Permissions.ensureGallery(context: context);
        return result.isGranted;
      case AssetSource.files:
        return true;
    }
  }
}
