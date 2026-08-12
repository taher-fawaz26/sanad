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
    required String name,
    required String categoryId,
    required String description,
    List<String>? imageIds,
  }) => _remoteDataSource
      .createServiceRequest(
        CreateServiceRequestDto(
          name: name,
          categoryId: categoryId,
          description: description,
          imageIds: imageIds,
        ),
      )
      .map((dto) => dto.toEntity());

  @override
  TaskEither<Failure, ServicesPagedResult<ServiceRequestEntity>>
  getServiceRequests({
    int page = 1,
    int limit = 10,
    String? search,
    ServiceRequestStatus? status,
  }) => _remoteDataSource
      .getServiceRequests(
        page: page,
        limit: limit,
        search: search,
        status: status,
      )
      .map(
        (paged) => ServicesPagedResult(
          items: paged.items.map((dto) => dto.toEntity()).toList(),
          meta: paged.meta,
        ),
      );

  @override
  TaskEither<Failure, ServiceRequestEntity> getServiceRequest(String id) =>
      _remoteDataSource.getServiceRequest(id).map((dto) => dto.toEntity());
}
