import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/service_request_entity.dart';
import 'package:services/src/domain/repositories/service_requests_repository.dart';

class GetServiceRequestUseCase
    implements UseCase<ServiceRequestEntity, String> {
  const GetServiceRequestUseCase(this._repository);

  final ServiceRequestsRepository _repository;

  @override
  TaskEither<Failure, ServiceRequestEntity> call(String id) =>
      _repository.getServiceRequest(id);
}
