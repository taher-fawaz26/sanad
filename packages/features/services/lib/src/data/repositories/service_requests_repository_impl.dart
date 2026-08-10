import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/data/datasources/services_remote_data_source.dart';
import 'package:services/src/data/models/create_service_request_dto.dart';
import 'package:services/src/domain/entities/pagination_meta_entity.dart';
import 'package:services/src/domain/entities/service_request_entity.dart';
import 'package:services/src/domain/entities/service_request_status.dart';
import 'package:services/src/domain/repositories/service_requests_repository.dart';

class ServiceRequestsRepositoryImpl implements ServiceRequestsRepository {
  const ServiceRequestsRepositoryImpl(this._remoteDataSource);

  final ServicesRemoteDataSource _remoteDataSource;

  @override
  TaskEither<Failure, ServiceRequestEntity> createServiceRequest({
    String? requestedServiceName,
    String? requestedCategoryName,
    required String description,
    required List<String> mediaIds,
  }) => _remoteDataSource
      .createServiceRequest(
        CreateServiceRequestDto(
          requestedServiceName: requestedServiceName,
          requestedCategoryName: requestedCategoryName,
          description: description,
          mediaIds: mediaIds,
        ),
      )
      .map((dto) => dto.toEntity());

  @override
  TaskEither<Failure, ServicesPagedResult<ServiceRequestEntity>>
  getMyServiceRequests({
    int page = 1,
    int limit = 10,
    ServiceRequestStatus? status,
  }) => _remoteDataSource
      .getMyServiceRequests(page: page, limit: limit, status: status)
      .map(
        (paged) => ServicesPagedResult(
          items: paged.items.map((dto) => dto.toEntity()).toList(),
          meta: paged.meta,
        ),
      );
}
