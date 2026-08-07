import 'package:account_settings/src/data/datasources/account_settings_remote_datasource.dart';
import 'package:account_settings/src/data/models/requests/update_account_settings_request.dart';
import 'package:account_settings/src/domain/entities/account_settings_entity.dart';
import 'package:account_settings/src/domain/repositories/account_settings_repository.dart';
import 'package:account_settings/src/domain/usecases/account_settings_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';

class AccountSettingsRepositoryImpl implements AccountSettingsRepository {
  const AccountSettingsRepositoryImpl(this._remote, this._networkGuard);

  final AccountSettingsRemoteDataSource _remote;
  final NetworkGuard _networkGuard;

  @override
  TaskEither<Failure, AccountSettingsEntity> getAccountSettings() =>
      _networkGuard.execute(
        action: _remote.getAccountSettings().map(
          (response) => response.toEntity(),
        ),
      );

  @override
  TaskEither<Failure, AccountSettingsEntity> updateAccountSettings(
    UpdateAccountSettingsParams params,
  ) => _networkGuard.execute(
    action: _remote
        .updateAccountSettings(
          UpdateAccountSettingsRequest(
            name: params.name,
            preferredLanguage: params.preferredLanguage,
          ),
        )
        .map((response) => response.toEntity()),
  );
}
