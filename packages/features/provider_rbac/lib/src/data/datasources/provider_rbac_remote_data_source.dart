import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:provider_rbac/src/data/endpoints/provider_rbac_api_paths.dart';
import 'package:provider_rbac/src/data/models/assign_worker_roles_dto.dart';
import 'package:provider_rbac/src/data/models/create_role_dto.dart';
import 'package:provider_rbac/src/data/models/permission_dto.dart';
import 'package:provider_rbac/src/data/models/role_dto.dart';
import 'package:provider_rbac/src/data/models/update_role_dto.dart';

/// Parses a plain-array response (roles/permissions endpoints are NOT
/// paginated, unlike most other SANAD list endpoints).
List<T> _parseList<T>(dynamic data, T Function(Map<String, dynamic>) parse) =>
    (data as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(parse)
        .toList();

abstract interface class ProviderRbacRemoteDataSource {
  TaskEither<Failure, List<RoleDto>> getRoles();
  TaskEither<Failure, RoleDto> createRole(CreateRoleDto dto);
  TaskEither<Failure, RoleDto> getRole(String id);
  TaskEither<Failure, RoleDto> updateRole(String id, UpdateRoleDto dto);
  TaskEither<Failure, Unit> deleteRole(String id);
  TaskEither<Failure, List<PermissionDto>> getPermissions();
  TaskEither<Failure, List<RoleDto>> getWorkerRoles(String workerId);
  TaskEither<Failure, List<RoleDto>> assignWorkerRoles(
    String workerId,
    AssignWorkerRolesDto dto,
  );
  TaskEither<Failure, Unit> removeWorkerRole(String workerId, String roleId);
}

class ProviderRbacRemoteDataSourceImpl implements ProviderRbacRemoteDataSource {
  const ProviderRbacRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, List<RoleDto>> getRoles() =>
      _apiClient.request<List<RoleDto>>(
        path: ProviderRbacApiPaths.roles,
        method: RequestMethod.get,
        parser: (data) => _parseList(data, RoleDto.fromJson),
      );

  @override
  TaskEither<Failure, RoleDto> createRole(CreateRoleDto dto) =>
      _apiClient.request<RoleDto>(
        path: ProviderRbacApiPaths.roles,
        method: RequestMethod.post,
        body: dto.toJson(),
        parser: (data) => RoleDto.fromJson(data as Map<String, dynamic>),
      );

  @override
  TaskEither<Failure, RoleDto> getRole(String id) =>
      _apiClient.request<RoleDto>(
        path: ProviderRbacApiPaths.role(id),
        method: RequestMethod.get,
        parser: (data) => RoleDto.fromJson(data as Map<String, dynamic>),
      );

  @override
  TaskEither<Failure, RoleDto> updateRole(String id, UpdateRoleDto dto) =>
      _apiClient.request<RoleDto>(
        path: ProviderRbacApiPaths.role(id),
        method: RequestMethod.patch,
        body: dto.toJson(),
        parser: (data) => RoleDto.fromJson(data as Map<String, dynamic>),
      );

  @override
  TaskEither<Failure, Unit> deleteRole(String id) => _apiClient.request<Unit>(
    path: ProviderRbacApiPaths.role(id),
    method: RequestMethod.delete,
    parser: (_) => unit,
  );

  @override
  TaskEither<Failure, List<PermissionDto>> getPermissions() =>
      _apiClient.request<List<PermissionDto>>(
        path: ProviderRbacApiPaths.permissions,
        method: RequestMethod.get,
        parser: (data) => _parseList(data, PermissionDto.fromJson),
      );

  @override
  TaskEither<Failure, List<RoleDto>> getWorkerRoles(String workerId) =>
      _apiClient.request<List<RoleDto>>(
        path: ProviderRbacApiPaths.workerRoles(workerId),
        method: RequestMethod.get,
        parser: (data) => _parseList(data, RoleDto.fromJson),
      );

  @override
  TaskEither<Failure, List<RoleDto>> assignWorkerRoles(
    String workerId,
    AssignWorkerRolesDto dto,
  ) => _apiClient.request<List<RoleDto>>(
    path: ProviderRbacApiPaths.workerRoles(workerId),
    method: RequestMethod.post,
    body: dto.toJson(),
    parser: (data) => _parseList(data, RoleDto.fromJson),
  );

  @override
  TaskEither<Failure, Unit> removeWorkerRole(String workerId, String roleId) =>
      _apiClient.request<Unit>(
        path: ProviderRbacApiPaths.workerRole(workerId, roleId),
        method: RequestMethod.delete,
        parser: (_) => unit,
      );
}
