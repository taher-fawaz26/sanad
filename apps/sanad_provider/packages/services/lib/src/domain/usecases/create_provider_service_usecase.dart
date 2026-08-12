import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/repositories/provider_services_repository.dart';

class CreateProviderServiceParams extends Equatable {
  const CreateProviderServiceParams({
    required this.serviceId,
    required this.description,
    required this.imageIds,
  });

  final String serviceId;
  final String description;
  final List<String> imageIds;

  @override
  List<Object?> get props => [serviceId, description, imageIds];
}

class CreateProviderServiceUseCase
    implements UseCase<ProviderServiceEntity, CreateProviderServiceParams> {
  const CreateProviderServiceUseCase(this._repository);

  final ProviderServicesRepository _repository;

  @override
  TaskEither<Failure, ProviderServiceEntity> call(
    CreateProviderServiceParams params,
  ) => _repository.createProviderService(
    serviceId: params.serviceId,
    description: params.description,
    imageIds: params.imageIds,
  );
}
