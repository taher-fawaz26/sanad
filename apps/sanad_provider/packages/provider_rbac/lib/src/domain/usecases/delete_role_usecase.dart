import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:provider_rbac/src/domain/repositories/roles_repository.dart';

class DeleteRoleParams extends Equatable {
  const DeleteRoleParams(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class DeleteRoleUseCase implements UseCase<Unit, DeleteRoleParams> {
  const DeleteRoleUseCase(this._repository);

  final RolesRepository _repository;

  @override
  TaskEither<Failure, Unit> call(DeleteRoleParams params) =>
      _repository.deleteRole(params.id);
}
