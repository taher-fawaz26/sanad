import 'package:account_settings/src/domain/entities/account_settings_entity.dart';
import 'package:account_settings/src/domain/usecases/account_settings_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

/// Updates the signed-in user's account settings.
///
/// There is no `GET /account-settings` on the live backend — only
/// `PATCH /account-settings` — so this repository only exposes the update
/// path. Reads are seeded from the auth session (`SessionManager`) instead;
/// see `AccountSettingsBloc`.
abstract interface class AccountSettingsRepository {
  TaskEither<Failure, AccountSettingsEntity> updateAccountSettings(
    UpdateAccountSettingsParams params,
  );
}
