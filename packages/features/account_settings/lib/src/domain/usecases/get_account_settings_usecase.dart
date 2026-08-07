import 'package:account_settings/src/domain/entities/account_settings_entity.dart';
import 'package:account_settings/src/domain/repositories/account_settings_repository.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class GetAccountSettingsUseCase
    implements UseCase<AccountSettingsEntity, NoParams> {
  const GetAccountSettingsUseCase(this._repository);

  final AccountSettingsRepository _repository;

  @override
  TaskEither<Failure, AccountSettingsEntity> call(NoParams params) =>
      _repository.getAccountSettings();
}
