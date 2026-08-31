import 'package:account_settings/src/data/endpoints/account_settings_api_paths.dart';
import 'package:account_settings/src/data/models/account_settings_response.dart';
import 'package:account_settings/src/data/models/requests/update_account_settings_request.dart';
import 'package:auth/auth.dart' show UserType;
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';

/// Remote data source for signed-in account settings.
///
/// There is no `GET /account-settings` on the live backend — only
/// `PATCH /account-settings` — so updates go through that endpoint, while
/// reads go through the persona-appropriate `GET /{persona}/profile`
/// envelope (see [AccountSettingsApiPaths.profilePathFor]).
abstract interface class AccountSettingsRemoteDataSource {
  /// Persona-aware update: clients patch `clients/me`, every other persona
  /// patches `account-settings` (which rejects clients with 403).
  TaskEither<Failure, AccountSettingsResponse> updateAccountSettings(
    UpdateAccountSettingsRequest request,
    UserType userType,
  );

  /// Fetches the persona-appropriate profile envelope for [userType] and
  /// extracts its embedded `accountSettings` object.
  TaskEither<Failure, AccountSettingsResponse> getAccountProfile(
    UserType userType,
  );
}

class AccountSettingsRemoteDataSourceImpl
    implements AccountSettingsRemoteDataSource {
  const AccountSettingsRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, AccountSettingsResponse> updateAccountSettings(
    UpdateAccountSettingsRequest request,
    UserType userType,
  ) => _apiClient.request<AccountSettingsResponse>(
    path: AccountSettingsApiPaths.updatePathFor(userType),
    method: RequestMethod.patch,
    body: request.toMap(),
    parser: (data) => AccountSettingsResponse.fromJson(
      data as Map<String, dynamic>,
    ),
  );

  @override
  TaskEither<Failure, AccountSettingsResponse> getAccountProfile(
    UserType userType,
  ) => _apiClient.request<AccountSettingsResponse>(
    path: AccountSettingsApiPaths.profilePathFor(userType),
    method: RequestMethod.get,
    parser: (data) {
      final envelope = data as Map<String, dynamic>;
      final accountSettings = envelope['accountSettings'];
      if (accountSettings is! Map<String, dynamic>) {
        throw const FormatException(
          'Profile response is missing the "accountSettings" object.',
        );
      }
      return AccountSettingsResponse.fromJson(accountSettings);
    },
  );
}
