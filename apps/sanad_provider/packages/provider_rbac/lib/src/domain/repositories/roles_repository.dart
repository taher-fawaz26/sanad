import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:provider_rbac/src/domain/usecases/roles_query.dart';

abstract interface class RolesRepository {
  TaskEither<Failure, Page<RoleEntity>> getRoles(RolesQuery query);

  TaskEither<Failure, RoleEntity> createRole({
    required String name,
    required String displayName,
    required List<String> permissionIds,
    String? displayNameAr,
    String? description,
    String? descriptionAr,
  });

  TaskEither<Failure, RoleEntity> getRole(String id);

  TaskEither<Failure, RoleEntity> updateRole({
    required String id,
    String? name,
    String? displayName,
    String? displayNameAr,
    String? description,
    String? descriptionAr,
    List<String>? permissionIds,
  });

  TaskEither<Failure, Unit> deleteRole(String id);

  TaskEither<Failure, List<RoleEntity>> getWorkerRoles(String workerId);

  TaskEither<Failure, List<RoleEntity>> assignWorkerRoles({
    required String workerId,
    required List<String> roleIds,
  });

  TaskEither<Failure, Unit> removeWorkerRole({
    required String workerId,
    required String roleId,
  });
}
