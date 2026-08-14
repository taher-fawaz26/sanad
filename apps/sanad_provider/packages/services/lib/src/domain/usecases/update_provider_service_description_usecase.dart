import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/repositories/provider_services_repository.dart';

class UpdateProviderServiceDescriptionParams extends Equatable {
  const UpdateProviderServiceDescriptionParams({
    required this.id,
    required this.description,
  });

  final String id;
  final String description;

  @override
  List<Object?> get props => [id, description];
}

class UpdateProviderServiceDescriptionUseCase
    implements
        UseCase<ProviderServiceEntity, UpdateProviderServiceDescriptionParams> {
  const UpdateProviderServiceDescriptionUseCase(this._repository);

  final ProviderServicesRepository _repository;

  @override
  TaskEither<Failure, ProviderServiceEntity> call(
    UpdateProviderServiceDescriptionParams params,
  ) => _repository.updateProviderService(
    id: params.id,
    description: params.description,
  );
}
