import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:provider_rbac/src/domain/repositories/roles_repository.dart';

class GetRolesUseCase implements UseCase<List<RoleEntity>, NoParams> {
  const GetRolesUseCase(this._repository);

  final RolesRepository _repository;

  @override
  TaskEither<Failure, List<RoleEntity>> call(NoParams params) =>
      _repository.getRoles();
}
