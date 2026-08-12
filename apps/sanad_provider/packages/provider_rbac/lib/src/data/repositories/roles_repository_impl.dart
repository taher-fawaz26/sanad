import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:provider_rbac/src/data/datasources/provider_rbac_remote_data_source.dart';
import 'package:provider_rbac/src/data/models/assign_worker_roles_dto.dart';
import 'package:provider_rbac/src/data/models/create_role_dto.dart';
import 'package:provider_rbac/src/data/models/update_role_dto.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:provider_rbac/src/domain/repositories/roles_repository.dart';
import 'package:provider_rbac/src/domain/usecases/roles_query.dart';

class RolesRepositoryImpl implements RolesRepository {
  const RolesRepositoryImpl(this._remoteDataSource);

  final ProviderRbacRemoteDataSource _remoteDataSource;

  @override
  TaskEither<Failure, Page<RoleEntity>> getRoles(RolesQuery query) =>
      _remoteDataSource
          .getRoles(query)
          .map((page) => page.mapItems((dto) => dto.toEntity()));

  @override
  TaskEither<Failure, RoleEntity> createRole({
    required String name,
    required String displayName,
    required List<String> permissionIds,
    String? displayNameAr,
    String? description,
    String? descriptionAr,
  }) => _remoteDataSource
      .createRole(
        CreateRoleDto(
          name: name,
          displayName: displayName,
          displayNameAr: displayNameAr,
          description: description,
          descriptionAr: descriptionAr,
          permissionIds: permissionIds,
        ),
      )
      .map((dto) => dto.toEntity());

  @override
  TaskEither<Failure, RoleEntity> getRole(String id) =>
      _remoteDataSource.getRole(id).map((dto) => dto.toEntity());

  @override
  TaskEither<Failure, RoleEntity> updateRole({
    required String id,
    String? name,
    String? displayName,
    String? displayNameAr,
    String? description,
    String? descriptionAr,
    List<String>? permissionIds,
  }) => _remoteDataSource
      .updateRole(
        id,
        UpdateRoleDto(
          name: name,
          displayName: displayName,
          displayNameAr: displayNameAr,
          description: description,
          descriptionAr: descriptionAr,
          permissionIds: permissionIds,
        ),
      )
      .map((dto) => dto.toEntity());

  @override
  TaskEither<Failure, Unit> deleteRole(String id) =>
      _remoteDataSource.deleteRole(id);

  @override
  TaskEither<Failure, List<RoleEntity>> getWorkerRoles(String workerId) =>
      _remoteDataSource
          .getWorkerRoles(workerId)
          .map((dtos) => dtos.map((dto) => dto.toEntity()).toList());

  @override
  TaskEither<Failure, List<RoleEntity>> assignWorkerRoles({
    required String workerId,
    required List<String> roleIds,
  }) => _remoteDataSource
      .assignWorkerRoles(workerId, AssignWorkerRolesDto(roleIds: roleIds))
      .map((dtos) => dtos.map((dto) => dto.toEntity()).toList());

  @override
  TaskEither<Failure, Unit> removeWorkerRole({
    required String workerId,
    required String roleId,
  }) => _remoteDataSource.removeWorkerRole(workerId, roleId);
}
