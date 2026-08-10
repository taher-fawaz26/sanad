import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:organization_settings/src/domain/entities/provider_completion_entity.dart';
import 'package:organization_settings/src/domain/repositories/organization_settings_repository.dart';

class GetProviderCompletionUseCase
    implements UseCase<ProviderCompletionEntity, NoParams> {
  const GetProviderCompletionUseCase(this._repository);

  final OrganizationSettingsRepository _repository;

  @override
  TaskEither<Failure, ProviderCompletionEntity> call(NoParams params) =>
      _repository.getCompletion();
}
