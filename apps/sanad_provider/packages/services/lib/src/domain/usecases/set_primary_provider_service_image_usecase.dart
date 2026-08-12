import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/repositories/provider_services_repository.dart';

class SetPrimaryProviderServiceImageParams extends Equatable {
  const SetPrimaryProviderServiceImageParams({
    required this.id,
    required this.imageId,
  });

  final String id;
  final String imageId;

  @override
  List<Object?> get props => [id, imageId];
}

class SetPrimaryProviderServiceImageUseCase
    implements
        UseCase<
          ProviderServiceEntity,
          SetPrimaryProviderServiceImageParams
        > {
  const SetPrimaryProviderServiceImageUseCase(this._repository);

  final ProviderServicesRepository _repository;

  @override
  TaskEither<Failure, ProviderServiceEntity> call(
    SetPrimaryProviderServiceImageParams params,
  ) => _repository.setPrimaryImage(id: params.id, imageId: params.imageId);
}
