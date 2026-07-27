import 'package:permissions/src/config/permission_config.dart';
import 'package:permissions/src/domain/entities/permission_result.dart';
import 'package:permissions/src/domain/enums/permission_type.dart';
import 'package:permissions/src/domain/services/permission_service.dart';
import 'package:permissions/src/infrastructure/providers/permission_handler_provider.dart';

class PermissionServiceImpl implements PermissionService {
  const PermissionServiceImpl(this._provider);

  final PermissionHandlerProvider _provider;

  @override
  Future<PermissionResult> check(PermissionType type) async {
    final status = await _provider.check(type);
    return PermissionResult(permission: type, status: status);
  }

  @override
  Future<Map<PermissionType, PermissionResult>> checkMany(
    List<PermissionType> types,
  ) async {
    final results = <PermissionType, PermissionResult>{};
    for (final type in types) {
      results[type] = await check(type);
    }
    return results;
  }

  @override
  Future<PermissionResult> request(
    PermissionType type, {
    PermissionPolicy? policy,
  }) async {
    final status = await _provider.request(type);
    return PermissionResult(permission: type, status: status);
  }

  @override
  Future<Map<PermissionType, PermissionResult>> requestMany(
    List<PermissionType> types, {
    PermissionPolicy? policy,
  }) async {
    final statuses = await _provider.requestMany(types);
    return {
      for (final entry in statuses.entries)
        entry.key: PermissionResult(
          permission: entry.key,
          status: entry.value,
        ),
    };
  }

  @override
  Future<bool> isGranted(PermissionType type) async =>
      (await check(type)).isGranted;

  @override
  Future<bool> isDenied(PermissionType type) async =>
      (await check(type)).isDenied;

  @override
  Future<bool> isLimited(PermissionType type) async =>
      (await check(type)).isLimited;

  @override
  Future<bool> isRestricted(PermissionType type) async =>
      (await check(type)).isRestricted;

  @override
  Future<bool> isPermanentlyDenied(PermissionType type) async =>
      (await check(type)).isPermanentlyDenied;

  @override
  Future<bool> openSettings() => _provider.openSettings();
}
