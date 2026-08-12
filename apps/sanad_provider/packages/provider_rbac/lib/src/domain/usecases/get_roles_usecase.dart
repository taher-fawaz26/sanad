import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:provider_rbac/src/domain/repositories/roles_repository.dart';
import 'package:provider_rbac/src/domain/usecases/roles_query.dart';

/// Lists worker roles for the current provider — `GET /provider/roles`.
/// Paginated per the live contract; the list screen accumulates pages via
/// [PaginationMixin], while the worker role-assignment catalog requests a
/// single large page.
class GetRolesUseCase implements UseCase<Page<RoleEntity>, RolesQuery> {
  const GetRolesUseCase(this._repository);

  final RolesRepository _repository;

  @override
  TaskEither<Failure, Page<RoleEntity>> call(RolesQuery params) =>
      _repository.getRoles(params);
}
