import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:provider_rbac/src/domain/repositories/roles_repository.dart';

class RemoveWorkerRoleParams extends Equatable {
  const RemoveWorkerRoleParams({required this.workerId, required this.roleId});

  final String workerId;
  final String roleId;

  @override
  List<Object?> get props => [workerId, roleId];
}

class RemoveWorkerRoleUseCase implements UseCase<Unit, RemoveWorkerRoleParams> {
  const RemoveWorkerRoleUseCase(this._repository);

  final RolesRepository _repository;

  @override
  TaskEither<Failure, Unit> call(RemoveWorkerRoleParams params) =>
      _repository.removeWorkerRole(
        workerId: params.workerId,
        roleId: params.roleId,
      );
}
