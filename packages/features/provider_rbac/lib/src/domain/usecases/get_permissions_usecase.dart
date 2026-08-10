import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:provider_rbac/src/domain/entities/permission_entity.dart';
import 'package:provider_rbac/src/domain/repositories/permissions_repository.dart';

class GetPermissionsUseCase
    implements UseCase<List<PermissionEntity>, NoParams> {
  const GetPermissionsUseCase(this._repository);

  final PermissionsRepository _repository;

  @override
  TaskEither<Failure, List<PermissionEntity>> call(NoParams params) =>
      _repository.getPermissions();
}
