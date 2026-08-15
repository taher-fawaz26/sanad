import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/repositories/provider_services_repository.dart';

class AddProviderServiceImageParams extends Equatable {
  const AddProviderServiceImageParams({
    required this.id,
    required this.mediaId,
  });

  final String id;
  final String mediaId;

  @override
  List<Object?> get props => [id, mediaId];
}

class AddProviderServiceImageUseCase
    implements UseCase<ProviderServiceEntity, AddProviderServiceImageParams> {
  const AddProviderServiceImageUseCase(this._repository);

  final ProviderServicesRepository _repository;

  @override
  TaskEither<Failure, ProviderServiceEntity> call(
    AddProviderServiceImageParams params,
  ) => _repository.addImage(id: params.id, mediaId: params.mediaId);
}
