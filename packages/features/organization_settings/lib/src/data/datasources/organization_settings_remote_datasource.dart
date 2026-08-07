import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:organization_settings/src/data/endpoints/organization_settings_api_paths.dart';
import 'package:organization_settings/src/data/models/service_provider_me_response.dart';

/// Remote data source for the organization's full settings profile —
/// `GET /service-provider/me`.
abstract interface class OrganizationSettingsRemoteDataSource {
  TaskEither<Failure, ServiceProviderMeResponse> getOrganizationSettings();
}

class OrganizationSettingsRemoteDataSourceImpl
    implements OrganizationSettingsRemoteDataSource {
  const OrganizationSettingsRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, ServiceProviderMeResponse> getOrganizationSettings() =>
      _apiClient.request<ServiceProviderMeResponse>(
        path: OrganizationSettingsApiPaths.me,
        method: RequestMethod.get,
        parser: (data) => ServiceProviderMeResponse.fromJson(
          data as Map<String, dynamic>,
        ),
      );
}
