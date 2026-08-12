import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/provider_service_overview_entity.dart';
import 'package:services/src/domain/repositories/provider_services_repository.dart';

class GetProviderServicesOverviewUseCase
    implements UseCase<ProviderServiceOverviewEntity, NoParams> {
  const GetProviderServicesOverviewUseCase(this._repository);

  final ProviderServicesRepository _repository;

  @override
  TaskEither<Failure, ProviderServiceOverviewEntity> call(NoParams params) =>
      _repository.getOverview();
}
