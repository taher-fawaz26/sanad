import 'package:account_settings/src/domain/entities/account_settings_entity.dart';
import 'package:account_settings/src/domain/repositories/account_settings_repository.dart';
import 'package:account_settings/src/domain/usecases/account_settings_params.dart';
import 'package:auth/auth.dart' show UserType;
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

/// Persists a partial account-settings update for the signed-in persona.
///
/// Takes [userType] (not the generic single-param [UseCase]) because the wire
/// endpoint differs by persona: clients patch `clients/me`, everyone else
/// patches `account-settings`. The caller supplies the persona from the
/// session ([AccountSettingsBloc]).
class UpdateAccountSettingsUseCase {
  const UpdateAccountSettingsUseCase(this._repository);

  final AccountSettingsRepository _repository;

  TaskEither<Failure, AccountSettingsEntity> call(
    UpdateAccountSettingsParams params,
    UserType userType,
  ) => _repository.updateAccountSettings(params, userType);
}
