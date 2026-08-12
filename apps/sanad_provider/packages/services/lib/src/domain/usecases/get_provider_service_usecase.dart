import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/repositories/provider_services_repository.dart';

class GetProviderServiceUseCase
    implements UseCase<ProviderServiceEntity, String> {
  const GetProviderServiceUseCase(this._repository);

  final ProviderServicesRepository _repository;

  @override
  TaskEither<Failure, ProviderServiceEntity> call(String id) =>
      _repository.getProviderService(id);
}
