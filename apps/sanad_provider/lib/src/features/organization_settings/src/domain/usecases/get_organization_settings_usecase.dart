import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/organization_profile_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/repositories/organization_settings_repository.dart';

class GetOrganizationSettingsUseCase
    implements UseCase<OrganizationProfileEntity, NoParams> {
  const GetOrganizationSettingsUseCase(this._repository);

  final OrganizationSettingsRepository _repository;

  @override
  TaskEither<Failure, OrganizationProfileEntity> call(NoParams params) =>
      _repository.getOrganizationSettings();
}
