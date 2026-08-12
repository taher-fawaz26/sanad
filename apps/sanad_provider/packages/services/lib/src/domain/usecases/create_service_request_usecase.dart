import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/service_request_entity.dart';
import 'package:services/src/domain/repositories/service_requests_repository.dart';

class CreateServiceRequestParams extends Equatable {
  const CreateServiceRequestParams({
    required this.name,
    required this.categoryId,
    required this.description,
    this.imageIds,
  });

  final String name;
  final String categoryId;
  final String description;
  final List<String>? imageIds;

  @override
  List<Object?> get props => [name, categoryId, description, imageIds];
}

class CreateServiceRequestUseCase
    implements UseCase<ServiceRequestEntity, CreateServiceRequestParams> {
  const CreateServiceRequestUseCase(this._repository);

  final ServiceRequestsRepository _repository;

  @override
  TaskEither<Failure, ServiceRequestEntity> call(
    CreateServiceRequestParams params,
  ) => _repository.createServiceRequest(
    name: params.name,
    categoryId: params.categoryId,
    description: params.description,
    imageIds: params.imageIds,
  );
}
