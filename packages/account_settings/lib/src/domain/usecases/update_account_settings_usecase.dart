import 'package:account_settings/src/domain/entities/account_settings_entity.dart';
import 'package:account_settings/src/domain/repositories/account_settings_repository.dart';
import 'package:account_settings/src/domain/usecases/account_settings_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class UpdateAccountSettingsUseCase
    implements UseCase<AccountSettingsEntity, UpdateAccountSettingsParams> {
  const UpdateAccountSettingsUseCase(this._repository);

  final AccountSettingsRepository _repository;

  @override
  TaskEither<Failure, AccountSettingsEntity> call(
    UpdateAccountSettingsParams params,
  ) => _repository.updateAccountSettings(params);
}
