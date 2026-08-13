import 'package:account_settings/src/domain/entities/account_settings_entity.dart';
import 'package:account_settings/src/domain/usecases/account_settings_params.dart';
import 'package:auth/auth.dart' show UserType;
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

/// Reads and updates the signed-in user's account settings.
///
/// There is no `GET /account-settings` on the live backend — only
/// `PATCH /account-settings` — so reads instead go through the
/// persona-appropriate `GET /{persona}/profile` envelope
/// ([getAccountProfile]). The session (`SessionManager`) is still the
/// screen's instant-render cache; see `AccountSettingsBloc`.
abstract interface class AccountSettingsRepository {
  TaskEither<Failure, AccountSettingsEntity> updateAccountSettings(
    UpdateAccountSettingsParams params,
  );

  /// Fetches the authoritative account settings for [userType] from its
  /// persona-appropriate profile endpoint.
  TaskEither<Failure, AccountSettingsEntity> getAccountProfile(
    UserType userType,
  );
}
