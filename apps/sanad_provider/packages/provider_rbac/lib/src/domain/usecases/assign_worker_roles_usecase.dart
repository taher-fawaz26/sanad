import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:provider_rbac/src/domain/repositories/roles_repository.dart';

/// Replaces the worker's existing roles with [roleIds] (per the live
/// `AssignWorkerRolesDto` contract — this is a replace, not an additive
/// merge; an empty list clears all roles).
class AssignWorkerRolesParams extends Equatable {
  const AssignWorkerRolesParams({
    required this.workerId,
    required this.roleIds,
  });

  final String workerId;
  final List<String> roleIds;

  @override
  List<Object?> get props => [workerId, roleIds];
}

class AssignWorkerRolesUseCase
    implements UseCase<List<RoleEntity>, AssignWorkerRolesParams> {
  const AssignWorkerRolesUseCase(this._repository);

  final RolesRepository _repository;

  @override
  TaskEither<Failure, List<RoleEntity>> call(
    AssignWorkerRolesParams params,
  ) => _repository.assignWorkerRoles(
    workerId: params.workerId,
    roleIds: params.roleIds,
  );
}
