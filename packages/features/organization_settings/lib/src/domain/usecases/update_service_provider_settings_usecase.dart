import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:organization_settings/src/domain/repositories/organization_settings_repository.dart';
import 'package:organization_settings/src/domain/usecases/update_service_provider_settings_params.dart';

class UpdateServiceProviderSettingsUseCase
    implements UseCase<Unit, UpdateServiceProviderSettingsParams> {
  const UpdateServiceProviderSettingsUseCase(this._repository);

  final OrganizationSettingsRepository _repository;

  @override
  TaskEither<Failure, Unit> call(
    UpdateServiceProviderSettingsParams params,
  ) => _repository.updateServiceProviderSettings(params);
}
