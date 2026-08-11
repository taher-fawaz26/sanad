import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:services/src/data/endpoints/services_api_paths.dart';
import 'package:services/src/data/models/category_record_dto.dart';
import 'package:services/src/data/models/create_service_dto.dart';
import 'package:services/src/data/models/create_service_request_dto.dart';
import 'package:services/src/data/models/service_analytics_dto.dart';
import 'package:services/src/data/models/service_record_dto.dart';
import 'package:services/src/data/models/service_request_dto.dart';
import 'package:services/src/data/models/services_paginated_response.dart';
import 'package:services/src/data/models/update_service_dto.dart';
import 'package:services/src/data/models/update_service_status_dto.dart';
import 'package:services/src/domain/entities/pagination_meta_entity.dart';
import 'package:services/src/domain/entities/service_analytics_entity.dart';
import 'package:services/src/domain/entities/service_request_status.dart';

/// Real backend integration for categories, the provider's own services
/// (CRUD + status + analytics), and service-requests (`create` + `mine`).
///
/// Distinct from the pre-existing `ServiceRemoteDataSource` (singular),
/// which backs the unrelated branch-service-assignment catalog and must not
/// be touched.
abstract interface class ServicesRemoteDataSource {
  TaskEither<Failure, ServicesPagedResult<CategoryRecordDto>> getCategories({
    required int page,
    required int limit,
    String? search,
  });

  TaskEither<Failure, ServiceRecordDto> createService(CreateServiceDto dto);

  TaskEither<Failure, ServicesPagedResult<ServiceRecordDto>> getServices({
    required int page,
    required int limit,
    String? search,
    String? categoryId,
    bool? isActive,
  });

  TaskEither<Failure, ServiceRecordDto> getService(String id);

  TaskEither<Failure, ServiceRecordDto> updateService(
    String id,
    UpdateServiceDto dto,
  );

  TaskEither<Failure, Unit> deleteService(String id);

  TaskEither<Failure, ServiceRecordDto> updateServiceStatus(
    String id,
    bool isActive,
  );

  TaskEither<Failure, ServiceAnalyticsEntity> getServiceAnalytics();

  TaskEither<Failure, ServiceRequestDto> createServiceRequest(
    CreateServiceRequestDto dto,
  );

  TaskEither<Failure, ServicesPagedResult<ServiceRequestDto>>
  getMyServiceRequests({
    required int page,
    required int limit,
    ServiceRequestStatus? status,
  });
}

class ServicesRemoteDataSourceImpl implements ServicesRemoteDataSource {
  const ServicesRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, ServicesPagedResult<CategoryRecordDto>> getCategories({
    required int page,
    required int limit,
    String? search,
  }) => _apiClient.request<ServicesPagedResult<CategoryRecordDto>>(
    path: ServicesApiPaths.categories,
    method: RequestMethod.get,
    query: {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
    },
    parser: (data) => parseServicesPage(data, CategoryRecordDto.fromJson),
  );

  @override
  TaskEither<Failure, ServiceRecordDto> createService(
    CreateServiceDto dto,
  ) => _apiClient.request<ServiceRecordDto>(
    path: ServicesApiPaths.services,
    method: RequestMethod.post,
    body: dto.toJson(),
    parser: (data) => ServiceRecordDto.fromJson(data as Map<String, dynamic>),
  );

  @override
  TaskEither<Failure, ServicesPagedResult<ServiceRecordDto>> getServices({
    required int page,
    required int limit,
    String? search,
    String? categoryId,
    bool? isActive,
  }) => _apiClient.request<ServicesPagedResult<ServiceRecordDto>>(
    path: ServicesApiPaths.services,
    method: RequestMethod.get,
    query: {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
      if (isActive != null) 'isActive': isActive,
    },
    parser: (data) => parseServicesPage(data, ServiceRecordDto.fromJson),
  );

  @override
  TaskEither<Failure, ServiceRecordDto> getService(String id) =>
      _apiClient.request<ServiceRecordDto>(
        path: ServicesApiPaths.service(id),
        method: RequestMethod.get,
        parser: (data) =>
            ServiceRecordDto.fromJson(data as Map<String, dynamic>),
      );

  @override
  TaskEither<Failure, ServiceRecordDto> updateService(
    String id,
    UpdateServiceDto dto,
  ) => _apiClient.request<ServiceRecordDto>(
    path: ServicesApiPaths.service(id),
    method: RequestMethod.patch,
    body: dto.toJson(),
    parser: (data) => ServiceRecordDto.fromJson(data as Map<String, dynamic>),
  );

  @override
  TaskEither<Failure, Unit> deleteService(String id) =>
      _apiClient.request<Unit>(
        path: ServicesApiPaths.service(id),
        method: RequestMethod.delete,
        parser: (_) => unit,
      );

  @override
  TaskEither<Failure, ServiceRecordDto> updateServiceStatus(
    String id,
    bool isActive,
  ) => _apiClient.request<ServiceRecordDto>(
    path: ServicesApiPaths.serviceStatus(id),
    method: RequestMethod.patch,
    body: UpdateServiceStatusDto(isActive: isActive).toJson(),
    parser: (data) => ServiceRecordDto.fromJson(data as Map<String, dynamic>),
  );

  @override
  TaskEither<Failure, ServiceAnalyticsEntity> getServiceAnalytics() =>
      _apiClient.request<ServiceAnalyticsEntity>(
        path: ServicesApiPaths.serviceAnalytics,
        method: RequestMethod.get,
        parser: (data) =>
            ServiceAnalyticsDto.fromJson(data as Map<String, dynamic>),
      );

  @override
  TaskEither<Failure, ServiceRequestDto> createServiceRequest(
    CreateServiceRequestDto dto,
  ) => _apiClient.request<ServiceRequestDto>(
    path: ServicesApiPaths.serviceRequests,
    method: RequestMethod.post,
    body: dto.toJson(),
    parser: (data) => ServiceRequestDto.fromJson(data as Map<String, dynamic>),
  );

  @override
  TaskEither<Failure, ServicesPagedResult<ServiceRequestDto>>
  getMyServiceRequests({
    required int page,
    required int limit,
    ServiceRequestStatus? status,
  }) => _apiClient.request<ServicesPagedResult<ServiceRequestDto>>(
    path: ServicesApiPaths.myServiceRequests,
    method: RequestMethod.get,
    query: {
      'page': page,
      'limit': limit,
      if (status != null) 'status': status.toApi(),
    },
    parser: (data) => parseServicesPage(data, ServiceRequestDto.fromJson),
  );
}
