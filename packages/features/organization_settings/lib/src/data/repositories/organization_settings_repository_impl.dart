import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:organization_settings/src/data/datasources/organization_settings_remote_datasource.dart';
import 'package:organization_settings/src/domain/entities/organization_settings_entity.dart';
import 'package:organization_settings/src/domain/repositories/organization_settings_repository.dart';

class OrganizationSettingsRepositoryImpl
    implements OrganizationSettingsRepository {
  const OrganizationSettingsRepositoryImpl(this._remote, this._networkGuard);

  final OrganizationSettingsRemoteDataSource _remote;
  final NetworkGuard _networkGuard;

  @override
  TaskEither<Failure, OrganizationSettingsEntity> getOrganizationSettings() =>
      _networkGuard.execute(
        action: _remote.getOrganizationSettings().map(
          (response) => response.toEntity(),
        ),
      );
}
