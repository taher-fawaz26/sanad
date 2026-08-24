import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:sanad_provider/src/features/home/src/data/endpoints/provider_statistics_api_paths.dart';
import 'package:sanad_provider/src/features/home/src/data/models/provider_statistic_response.dart';

/// Remote data source for `service-provider/statistics`.
abstract interface class ProviderStatisticsRemoteDataSource {
  TaskEither<Failure, ProviderStatisticsResponse> getStatistics();
}

class ProviderStatisticsRemoteDataSourceImpl
    implements ProviderStatisticsRemoteDataSource {
  const ProviderStatisticsRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, ProviderStatisticsResponse> getStatistics() =>
      _apiClient.request<ProviderStatisticsResponse>(
        path: ProviderStatisticsApiPaths.statistics,
        method: RequestMethod.get,
        parser: (data) =>
            ProviderStatisticsResponse.fromJson(data as Map<String, dynamic>),
      );
}
