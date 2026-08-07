import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:organization_settings/src/domain/entities/organization_settings_entity.dart';
import 'package:organization_settings/src/domain/repositories/organization_settings_repository.dart';

class GetOrganizationSettingsUseCase
    implements UseCase<OrganizationSettingsEntity, NoParams> {
  const GetOrganizationSettingsUseCase(this._repository);

  final OrganizationSettingsRepository _repository;

  @override
  TaskEither<Failure, OrganizationSettingsEntity> call(NoParams params) =>
      _repository.getOrganizationSettings();
}
