import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:provider_rbac/src/domain/repositories/roles_repository.dart';

class GetWorkerRolesParams extends Equatable {
  const GetWorkerRolesParams(this.workerId);

  final String workerId;

  @override
  List<Object?> get props => [workerId];
}

class GetWorkerRolesUseCase
    implements UseCase<List<RoleEntity>, GetWorkerRolesParams> {
  const GetWorkerRolesUseCase(this._repository);

  final RolesRepository _repository;

  @override
  TaskEither<Failure, List<RoleEntity>> call(GetWorkerRolesParams params) =>
      _repository.getWorkerRoles(params.workerId);
}
