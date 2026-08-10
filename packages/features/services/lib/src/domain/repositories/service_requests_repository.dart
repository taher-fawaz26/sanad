import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/pagination_meta_entity.dart';
import 'package:services/src/domain/entities/service_request_entity.dart';
import 'package:services/src/domain/entities/service_request_status.dart';

/// `POST /service-requests` + `GET /service-requests/mine`.
///
/// `GET /service-requests` (all) and `PATCH .../review` are admin-only and
/// out of scope for this provider-facing package.
abstract interface class ServiceRequestsRepository {
  TaskEither<Failure, ServiceRequestEntity> createServiceRequest({
    String? requestedServiceName,
    String? requestedCategoryName,
    required String description,
    required List<String> mediaIds,
  });

  TaskEither<Failure, ServicesPagedResult<ServiceRequestEntity>>
  getMyServiceRequests({
    int page = 1,
    int limit = 10,
    ServiceRequestStatus? status,
  });
}
