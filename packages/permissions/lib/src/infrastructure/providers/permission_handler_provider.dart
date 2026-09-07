import 'dart:io';

import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:permissions/src/domain/enums/permission_status.dart';
import 'package:permissions/src/domain/enums/permission_type.dart';

/// The ONLY file in the monorepo that may import `permission_handler`.
///
/// Translates between our strongly-typed domain model and the raw
/// permission_handler API. No type from `permission_handler` ever escapes
/// this class.
class PermissionHandlerProvider {
  const PermissionHandlerProvider();

  Future<PermissionStatus> check(PermissionType type) async {
    final status = await _toNative(type).status;
    return _fromNative(status);
  }

  Future<PermissionStatus> request(PermissionType type) async {
    final status = await _toNative(type).request();
    return _fromNative(status);
  }

  Future<Map<PermissionType, PermissionStatus>> requestMany(
    List<PermissionType> types,
  ) async {
    // Build the mapping once so we use the same Permission instances for
    // both the batch request and the result lookup.
    final typeToNative = {for (final t in types) t: _toNative(t)};
    final statuses = await typeToNative.values.toList().request();

    return {
      for (final entry in typeToNative.entries)
        entry.key: _fromNative(
          statuses[entry.value] ?? ph.PermissionStatus.denied,
        ),
    };
  }

  Future<bool> openSettings() => ph.openAppSettings();

  // ---------------------------------------------------------------------------
  // Mapping: PermissionType → ph.Permission
  // ---------------------------------------------------------------------------

  ph.Permission _toNative(PermissionType type) {
    return switch (type) {
      PermissionType.camera => ph.Permission.camera,
      PermissionType.photos => ph.Permission.photos,
      // permission_handler ≥10.2 routes Permission.photos to READ_MEDIA_IMAGES
      // on Android 13+ (API 33+) and READ_EXTERNAL_STORAGE on older versions.
      // Permission.storage maps to READ_EXTERNAL_STORAGE only, which Android
      // marks permanentlyDenied immediately on API 33+ — never use it for gallery.
      PermissionType.gallery => ph.Permission.photos,
      PermissionType.storage => ph.Permission.storage,
      // iOS has no separate documents permission (document picker handles it
      // in-UI). On Android we request MANAGE_EXTERNAL_STORAGE.
      PermissionType.documents =>
        Platform.isIOS
            ? ph.Permission.photos
            : ph.Permission.manageExternalStorage,
      PermissionType.microphone => ph.Permission.microphone,
      // One native permission covers both platforms: `Permission.speech` is
      // RECORD_AUDIO on Android and `SFSpeechRecognizer` authorization on iOS,
      // so no `Platform` branch is needed here.
      PermissionType.speechRecognition => ph.Permission.speech,
      PermissionType.locationWhenInUse => ph.Permission.locationWhenInUse,
      PermissionType.locationAlways => ph.Permission.locationAlways,
      PermissionType.notifications => ph.Permission.notification,
      PermissionType.contacts => ph.Permission.contacts,
      // calendarFullAccess covers both read and write on iOS 17+.
      PermissionType.calendar => ph.Permission.calendarFullAccess,
      PermissionType.bluetooth => ph.Permission.bluetooth,
      // Android 12+: NEARBY_WIFI_DEVICES; iOS: Bluetooth covers the same UX.
      PermissionType.nearbyDevices =>
        Platform.isIOS
            ? ph.Permission.bluetooth
            : ph.Permission.nearbyWifiDevices,
      // READ_PHONE_STATE is Android-only; iOS has no equivalent.
      PermissionType.phone => ph.Permission.phone,
      // Apple Music / media library — iOS only.
      PermissionType.mediaLibrary => ph.Permission.mediaLibrary,
      PermissionType.manageExternalStorage =>
        ph.Permission.manageExternalStorage,
    };
  }

  // ---------------------------------------------------------------------------
  // Mapping: ph.PermissionStatus → PermissionStatus
  // ---------------------------------------------------------------------------

  PermissionStatus _fromNative(ph.PermissionStatus status) {
    return switch (status) {
      ph.PermissionStatus.granted => PermissionStatus.granted,
      ph.PermissionStatus.denied => PermissionStatus.denied,
      ph.PermissionStatus.permanentlyDenied =>
        PermissionStatus.permanentlyDenied,
      ph.PermissionStatus.restricted => PermissionStatus.restricted,
      ph.PermissionStatus.limited => PermissionStatus.limited,
      ph.PermissionStatus.provisional => PermissionStatus.provisional,
    };
  }
}
