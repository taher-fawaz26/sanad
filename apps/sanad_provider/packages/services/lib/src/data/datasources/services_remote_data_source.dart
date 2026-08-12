import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:services/src/data/endpoints/services_api_paths.dart';
import 'package:services/src/data/models/category_record_dto.dart';
import 'package:services/src/data/models/create_service_request_dto.dart';
import 'package:services/src/data/models/service_request_dto.dart';
import 'package:services/src/data/models/services_paginated_response.dart';
import 'package:services/src/domain/entities/pagination_meta_entity.dart';
import 'package:services/src/domain/entities/service_request_status.dart';

/// Real backend integration for categories and service-requests
/// (`create`/`list`/`detail`). The provider's own services live behind
/// [ProviderServicesRemoteDataSource] and the catalog behind
/// [CatalogRemoteDataSource] instead.
abstract interface class ServicesRemoteDataSource {
  TaskEither<Failure, ServicesPagedResult<CategoryRecordDto>> getCategories({
    required int page,
    required int limit,
    String? search,
  });

  TaskEither<Failure, ServiceRequestDto> createServiceRequest(
    CreateServiceRequestDto dto,
  );

  TaskEither<Failure, ServicesPagedResult<ServiceRequestDto>>
  getServiceRequests({
    required int page,
    required int limit,
    String? search,
    ServiceRequestStatus? status,
  });

  TaskEither<Failure, ServiceRequestDto> getServiceRequest(String id);
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
  getServiceRequests({
    required int page,
    required int limit,
    String? search,
    ServiceRequestStatus? status,
  }) => _apiClient.request<ServicesPagedResult<ServiceRequestDto>>(
    path: ServicesApiPaths.serviceRequests,
    method: RequestMethod.get,
    query: {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status != ServiceRequestStatus.all)
        'status': status.toApi(),
    },
    parser: (data) => parseServicesPage(data, ServiceRequestDto.fromJson),
  );

  @override
  TaskEither<Failure, ServiceRequestDto> getServiceRequest(String id) =>
      _apiClient.request<ServiceRequestDto>(
        path: ServicesApiPaths.serviceRequest(id),
        method: RequestMethod.get,
        parser: (data) =>
            ServiceRequestDto.fromJson(data as Map<String, dynamic>),
      );
}
