import 'package:account_settings/src/data/endpoints/account_settings_api_paths.dart';
import 'package:account_settings/src/data/models/account_settings_response.dart';
import 'package:account_settings/src/data/models/requests/update_account_settings_request.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';

/// Remote data source for signed-in account settings.
abstract interface class AccountSettingsRemoteDataSource {
  TaskEither<Failure, AccountSettingsResponse> getAccountSettings();

  TaskEither<Failure, AccountSettingsResponse> updateAccountSettings(
    UpdateAccountSettingsRequest request,
  );
}

class AccountSettingsRemoteDataSourceImpl
    implements AccountSettingsRemoteDataSource {
  const AccountSettingsRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, AccountSettingsResponse> getAccountSettings() =>
      _apiClient.request<AccountSettingsResponse>(
        path: AccountSettingsApiPaths.accountSettings,
        method: RequestMethod.get,
        parser: (data) => AccountSettingsResponse.fromJson(
          data as Map<String, dynamic>,
        ),
      );

  @override
  TaskEither<Failure, AccountSettingsResponse> updateAccountSettings(
    UpdateAccountSettingsRequest request,
  ) => _apiClient.request<AccountSettingsResponse>(
    path: AccountSettingsApiPaths.accountSettings,
    method: RequestMethod.patch,
    body: request.toMap(),
    parser: (data) => AccountSettingsResponse.fromJson(
      data as Map<String, dynamic>,
    ),
  );
}
