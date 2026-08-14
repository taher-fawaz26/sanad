import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/repositories/provider_services_repository.dart';

class DeleteProviderServiceImageParams extends Equatable {
  const DeleteProviderServiceImageParams({
    required this.id,
    required this.imageId,
  });

  final String id;
  final String imageId;

  @override
  List<Object?> get props => [id, imageId];
}

class DeleteProviderServiceImageUseCase
    implements
        UseCase<ProviderServiceEntity, DeleteProviderServiceImageParams> {
  const DeleteProviderServiceImageUseCase(this._repository);

  final ProviderServicesRepository _repository;

  @override
  TaskEither<Failure, ProviderServiceEntity> call(
    DeleteProviderServiceImageParams params,
  ) => _repository.deleteImage(id: params.id, imageId: params.imageId);
}
