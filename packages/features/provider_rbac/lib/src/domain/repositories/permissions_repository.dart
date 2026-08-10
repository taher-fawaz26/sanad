import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:provider_rbac/src/domain/entities/permission_entity.dart';

abstract interface class PermissionsRepository {
  TaskEither<Failure, List<PermissionEntity>> getPermissions();
}
