import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/provider_service_overview_entity.dart';
import 'package:services/src/domain/repositories/provider_services_repository.dart';

class GetProviderServiceOverviewUseCase
    implements UseCase<ProviderServiceOverviewEntity, String> {
  const GetProviderServiceOverviewUseCase(this._repository);

  final ProviderServicesRepository _repository;

  @override
  TaskEither<Failure, ProviderServiceOverviewEntity> call(String id) =>
      _repository.getOverviewFor(id);
}
