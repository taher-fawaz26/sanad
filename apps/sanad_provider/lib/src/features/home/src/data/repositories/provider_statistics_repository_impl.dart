import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:sanad_provider/src/features/home/src/data/datasources/provider_statistics_remote_datasource.dart';
import 'package:sanad_provider/src/features/home/src/domain/entities/provider_statistic_entity.dart';
import 'package:sanad_provider/src/features/home/src/domain/repositories/provider_statistics_repository.dart';

class ProviderStatisticsRepositoryImpl
    implements ProviderStatisticsRepository {
  const ProviderStatisticsRepositoryImpl(this._remote, this._networkGuard);

  final ProviderStatisticsRemoteDataSource _remote;
  final NetworkGuard _networkGuard;

  @override
  TaskEither<Failure, List<ProviderStatisticEntity>> getStatistics() =>
      _networkGuard.execute(
        action: _remote.getStatistics().map((response) => response.toEntity()),
      );
}
