import 'package:account_settings/src/domain/entities/account_settings_entity.dart';
import 'package:account_settings/src/domain/usecases/account_settings_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

/// Reads and updates the signed-in user's account settings.
abstract interface class AccountSettingsRepository {
  TaskEither<Failure, AccountSettingsEntity> getAccountSettings();

  TaskEither<Failure, AccountSettingsEntity> updateAccountSettings(
    UpdateAccountSettingsParams params,
  );
}
