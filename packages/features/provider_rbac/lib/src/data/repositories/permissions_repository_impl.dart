import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:provider_rbac/src/data/datasources/provider_rbac_remote_data_source.dart';
import 'package:provider_rbac/src/domain/entities/permission_entity.dart';
import 'package:provider_rbac/src/domain/repositories/permissions_repository.dart';

class PermissionsRepositoryImpl implements PermissionsRepository {
  const PermissionsRepositoryImpl(this._remoteDataSource);

  final ProviderRbacRemoteDataSource _remoteDataSource;

  @override
  TaskEither<Failure, List<PermissionEntity>> getPermissions() =>
      _remoteDataSource.getPermissions().map(
        (dtos) => dtos.map((dto) => dto.toEntity()).toList(),
      );
}
