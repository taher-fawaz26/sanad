import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:provider_rbac/src/domain/repositories/roles_repository.dart';

class GetRoleParams extends Equatable {
  const GetRoleParams(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class GetRoleUseCase implements UseCase<RoleEntity, GetRoleParams> {
  const GetRoleUseCase(this._repository);

  final RolesRepository _repository;

  @override
  TaskEither<Failure, RoleEntity> call(GetRoleParams params) =>
      _repository.getRole(params.id);
}
