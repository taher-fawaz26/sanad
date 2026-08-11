import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/endpoints/provider_overview_api_paths.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/provider_overview_response.dart';

/// Remote data source for `service-provider/overview`.
abstract interface class ProviderOverviewRemoteDataSource {
  TaskEither<Failure, ProviderOverviewResponse> getOverview();
}

class ProviderOverviewRemoteDataSourceImpl
    implements ProviderOverviewRemoteDataSource {
  const ProviderOverviewRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, ProviderOverviewResponse> getOverview() =>
      _apiClient.request<ProviderOverviewResponse>(
        path: ProviderOverviewApiPaths.overview,
        method: RequestMethod.get,
        parser: (data) =>
            ProviderOverviewResponse.fromJson(data as Map<String, dynamic>),
      );
}
