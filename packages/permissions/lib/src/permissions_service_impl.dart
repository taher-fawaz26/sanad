import 'package:permission_handler/permission_handler.dart';
import 'package:permissions/src/permissions_service.dart';

/// Default implementation that delegates to `permission_handler`.
///
/// Register as a lazy singleton in each app's `app_di.dart`:
/// ```dart
/// sl.registerLazySingleton<PermissionsService>(
///   () => PermissionsServiceImpl(),
/// );
/// ```
class PermissionsServiceImpl implements PermissionsService {
  const PermissionsServiceImpl();

  @override
  Future<PermissionStatus> check(Permission permission) =>
      permission.status;

  @override
  Future<PermissionRequestResult> request(Permission permission) async {
    final status = await permission.request();
    return _mapStatus(status);
  }

  @override
  Future<Map<Permission, PermissionRequestResult>> requestMultiple(
    List<Permission> permissions,
  ) async {
    final statuses = await permissions.request();
    return {
      for (final entry in statuses.entries)
        entry.key: _mapStatus(entry.value),
    };
  }

  @override
  Future<bool> openSettings() => openAppSettings();

  PermissionRequestResult _mapStatus(PermissionStatus status) {
    return switch (status) {
      PermissionStatus.granted ||
      PermissionStatus.limited ||
      PermissionStatus.provisional => PermissionRequestResult.granted,
      PermissionStatus.denied => PermissionRequestResult.denied,
      PermissionStatus.permanentlyDenied ||
      PermissionStatus.restricted => PermissionRequestResult.permanentlyDenied,
    };
  }
}
