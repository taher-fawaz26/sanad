import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/service_request_entity.dart';
import 'package:services/src/domain/repositories/service_requests_repository.dart';

class CreateServiceRequestParams extends Equatable {
  const CreateServiceRequestParams({
    this.requestedServiceName,
    this.requestedCategoryName,
    required this.description,
    required this.mediaIds,
  });

  final String? requestedServiceName;
  final String? requestedCategoryName;
  final String description;
  final List<String> mediaIds;

  @override
  List<Object?> get props => [
    requestedServiceName,
    requestedCategoryName,
    description,
    mediaIds,
  ];
}

class CreateServiceRequestUseCase
    implements UseCase<ServiceRequestEntity, CreateServiceRequestParams> {
  const CreateServiceRequestUseCase(this._repository);

  final ServiceRequestsRepository _repository;

  @override
  TaskEither<Failure, ServiceRequestEntity> call(
    CreateServiceRequestParams params,
  ) => _repository.createServiceRequest(
    requestedServiceName: params.requestedServiceName,
    requestedCategoryName: params.requestedCategoryName,
    description: params.description,
    mediaIds: params.mediaIds,
  );
}
