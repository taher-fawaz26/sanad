import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/datasources/provider_overview_remote_datasource.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/provider_overview_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/repositories/provider_overview_repository.dart';

class ProviderOverviewRepositoryImpl implements ProviderOverviewRepository {
  const ProviderOverviewRepositoryImpl(this._remote, this._networkGuard);

  final ProviderOverviewRemoteDataSource _remote;
  final NetworkGuard _networkGuard;

  @override
  TaskEither<Failure, ProviderOverviewEntity> getOverview() =>
      _networkGuard.execute(
        action: _remote.getOverview().map((response) => response.toEntity()),
      );
}
