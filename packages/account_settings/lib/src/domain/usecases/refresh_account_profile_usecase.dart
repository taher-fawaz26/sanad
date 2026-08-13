import 'package:account_settings/src/domain/entities/account_settings_entity.dart';
import 'package:account_settings/src/domain/repositories/account_settings_repository.dart';
import 'package:auth/auth.dart' show GetCurrentUserUseCase;
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

/// Refreshes account settings from the live backend.
///
/// There is no direct `GET /account-settings`, so this composes the
/// persona-aware contract: `GET /me` to discover the signed-in persona, then
/// the matching `GET /{persona}/profile` for the authoritative
/// `accountSettings` snapshot.
class RefreshAccountProfileUseCase
    implements UseCase<AccountSettingsEntity, NoParams> {
  const RefreshAccountProfileUseCase(this._getCurrentUser, this._repository);

  final GetCurrentUserUseCase _getCurrentUser;
  final AccountSettingsRepository _repository;

  @override
  TaskEither<Failure, AccountSettingsEntity> call(NoParams params) =>
      _getCurrentUser(const NoParams()).flatMap(
        (identity) => _repository.getAccountProfile(identity.userType),
      );
}
