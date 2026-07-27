import 'package:permissions/src/config/permission_config.dart';
import 'package:permissions/src/domain/entities/permission_result.dart';
import 'package:permissions/src/domain/enums/permission_type.dart';

/// Abstract contract for the permission service.
///
/// Feature packages depend only on this interface. The concrete implementation
/// ([PermissionServiceImpl]) is wired by [PermissionsDI] and never imported
/// by any package other than `permissions`.
abstract class PermissionService {
  /// Checks the current [PermissionStatus] without prompting the user.
  Future<PermissionResult> check(PermissionType type);

  /// Checks multiple permissions in sequence without prompting the user.
  Future<Map<PermissionType, PermissionResult>> checkMany(
    List<PermissionType> types,
  );

  /// Requests a single permission from the OS.
  ///
  /// [policy] overrides the app-wide default from [PermissionConfig].
  Future<PermissionResult> request(
    PermissionType type, {
    PermissionPolicy? policy,
  });

  /// Requests multiple permissions in a single OS-level batch.
  ///
  /// [policy] applies to all permissions in the batch.
  Future<Map<PermissionType, PermissionResult>> requestMany(
    List<PermissionType> types, {
    PermissionPolicy? policy,
  });

  /// Returns `true` if [type] is currently granted (includes limited/provisional).
  Future<bool> isGranted(PermissionType type);

  /// Returns `true` if [type] was denied but can still be re-requested.
  Future<bool> isDenied(PermissionType type);

  /// Returns `true` when the user has granted only partial access (iOS limited
  /// photo selection).
  Future<bool> isLimited(PermissionType type);

  /// Returns `true` when an OS policy blocks the permission (MDM, parental
  /// controls).
  Future<bool> isRestricted(PermissionType type);

  /// Returns `true` if the user selected "Don't ask again" or denied twice on
  /// iOS; navigating to settings is the only recovery path.
  Future<bool> isPermanentlyDenied(PermissionType type);

  /// Opens the host app's entry in the device settings.
  Future<bool> openSettings();
}
