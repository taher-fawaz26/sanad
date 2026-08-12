import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/pagination_meta_entity.dart';
import 'package:services/src/domain/entities/service_request_entity.dart';
import 'package:services/src/domain/entities/service_request_status.dart';

/// `POST /service-requests`, `GET /service-requests`, and
/// `GET /service-requests/:id`.
abstract interface class ServiceRequestsRepository {
  TaskEither<Failure, ServiceRequestEntity> createServiceRequest({
    required String name,
    required String categoryId,
    required String description,
    List<String>? imageIds,
  });

  TaskEither<Failure, ServicesPagedResult<ServiceRequestEntity>>
  getServiceRequests({
    int page = 1,
    int limit = 10,
    String? search,
    ServiceRequestStatus? status,
  });

  TaskEither<Failure, ServiceRequestEntity> getServiceRequest(String id);
}
