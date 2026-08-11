import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/endpoints/organization_settings_api_paths.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/endpoints/provider_completion_api_paths.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/endpoints/service_provider_settings_api_paths.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/me_settings_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/provider_completion_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/usecases/update_service_provider_settings_params.dart';

/// Remote data source for the organization's business profile —
/// `GET /settings`, `PATCH service-provider/settings`, and
/// `GET service-provider/completion`.
abstract interface class OrganizationSettingsRemoteDataSource {
  TaskEither<Failure, MeSettingsResponse> getOrganizationSettings();

  /// `PATCH service-provider/settings` → `204 No Content`.
  TaskEither<Failure, Unit> updateServiceProviderSettings(
    UpdateServiceProviderSettingsParams params,
  );

  TaskEither<Failure, ProviderCompletionResponse> getCompletion();
}

class OrganizationSettingsRemoteDataSourceImpl
    implements OrganizationSettingsRemoteDataSource {
  const OrganizationSettingsRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, MeSettingsResponse> getOrganizationSettings() =>
      _apiClient.request<MeSettingsResponse>(
        path: OrganizationSettingsApiPaths.settings,
        method: RequestMethod.get,
        parser: (data) =>
            MeSettingsResponse.fromJson(data as Map<String, dynamic>),
      );

  @override
  TaskEither<Failure, Unit> updateServiceProviderSettings(
    UpdateServiceProviderSettingsParams params,
  ) => _apiClient.request<Unit>(
    path: ServiceProviderSettingsApiPaths.settings,
    method: RequestMethod.patch,
    body: {
      if (params.description != null) 'description': params.description,
      if (params.categoryIds != null) 'categoryIds': params.categoryIds,
      if (params.socialProfiles != null)
        'socialProfiles': params.socialProfiles,
    },
    // 204 No Content — no response body to parse.
    parser: (_) => unit,
  );

  @override
  TaskEither<Failure, ProviderCompletionResponse> getCompletion() =>
      _apiClient.request<ProviderCompletionResponse>(
        path: ProviderCompletionApiPaths.completion,
        method: RequestMethod.get,
        parser: (data) => ProviderCompletionResponse.fromJson(
          data as Map<String, dynamic>,
        ),
      );
}
