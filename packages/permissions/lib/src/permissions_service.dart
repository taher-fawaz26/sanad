import 'package:permission_handler/permission_handler.dart';

/// Result of a single permission request.
enum PermissionRequestResult {
  /// The user granted the permission.
  granted,

  /// The user denied the permission (can be re-requested).
  denied,

  /// The user permanently denied the permission.
  /// Call [PermissionsService.openSettings] to let the user fix this.
  permanentlyDenied,

  /// The device does not support this permission.
  notRequired,
}

/// Contract for checking and requesting device permissions.
///
/// Feature packages depend on this abstract class; apps register a
/// concrete implementation via DI.
abstract class PermissionsService {
  /// Returns the current [PermissionStatus] for [permission] without
  /// triggering the system dialog.
  Future<PermissionStatus> check(Permission permission);

  /// Requests [permission] from the user.
  ///
  /// Returns a normalised [PermissionRequestResult] that callers can
  /// switch on without importing permission_handler directly.
  Future<PermissionRequestResult> request(Permission permission);

  /// Requests multiple [permissions] in one call.
  ///
  /// Returns a map of each [Permission] to its [PermissionRequestResult].
  Future<Map<Permission, PermissionRequestResult>> requestMultiple(
    List<Permission> permissions,
  );

  /// Opens the OS app-settings screen so the user can manually grant
  /// a permanently-denied permission.
  Future<bool> openSettings();
}
