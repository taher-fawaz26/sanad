import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:services/src/data/endpoints/services_api_paths.dart';
import 'package:services/src/data/models/add_provider_service_image_dto.dart';
import 'package:services/src/data/models/create_provider_service_dto.dart';
import 'package:services/src/data/models/provider_service_dto.dart';
import 'package:services/src/data/models/provider_service_image_dto.dart';
import 'package:services/src/data/models/provider_service_overview_dto.dart';
import 'package:services/src/data/models/services_paginated_response.dart';
import 'package:services/src/data/models/update_provider_service_dto.dart';
import 'package:services/src/data/models/update_provider_service_status_dto.dart';
import 'package:services/src/domain/entities/pagination_meta_entity.dart';
import 'package:services/src/domain/entities/provider_service_status.dart';

/// The provider's own offered services — CRUD, status, overview, and image
/// lifecycle (`/provider-services*`).
abstract interface class ProviderServicesRemoteDataSource {
  TaskEither<Failure, ServicesPagedResult<ProviderServiceDto>>
  listProviderServices({
    required int page,
    required int limit,
    String? search,
    ProviderServiceStatus? status,
  });

  TaskEither<Failure, ProviderServiceDto> getProviderService(String id);

  TaskEither<Failure, ProviderServiceDto> createProviderService(
    CreateProviderServiceDto dto,
  );

  TaskEither<Failure, ProviderServiceDto> updateProviderService(
    String id,
    UpdateProviderServiceDto dto,
  );

  TaskEither<Failure, Unit> deleteProviderService(String id);

  TaskEither<Failure, ProviderServiceDto> updateProviderServiceStatus(
    String id,
    ProviderServiceStatus status,
  );

  TaskEither<Failure, ProviderServiceOverviewDto> getOverview();

  TaskEither<Failure, ProviderServiceOverviewDto> getOverviewFor(String id);

  TaskEither<Failure, ProviderServiceImageDto> addImage(
    String id,
    String mediaId,
  );

  TaskEither<Failure, Unit> deleteImage(String id, String imageId);

  TaskEither<Failure, ProviderServiceDto> setPrimaryImage(
    String id,
    String imageId,
  );
}

class ProviderServicesRemoteDataSourceImpl
    implements ProviderServicesRemoteDataSource {
  const ProviderServicesRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, ServicesPagedResult<ProviderServiceDto>>
  listProviderServices({
    required int page,
    required int limit,
    String? search,
    ProviderServiceStatus? status,
  }) => _apiClient.request<ServicesPagedResult<ProviderServiceDto>>(
    path: ServicesApiPaths.providerServices,
    method: RequestMethod.get,
    query: {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null) 'status': status.toApi(),
    },
    parser: (data) => parseServicesPage(data, ProviderServiceDto.fromJson),
  );

  @override
  TaskEither<Failure, ProviderServiceDto> getProviderService(String id) =>
      _apiClient.request<ProviderServiceDto>(
        path: ServicesApiPaths.providerService(id),
        method: RequestMethod.get,
        parser: (data) =>
            ProviderServiceDto.fromJson(data as Map<String, dynamic>),
      );

  @override
  TaskEither<Failure, ProviderServiceDto> createProviderService(
    CreateProviderServiceDto dto,
  ) => _apiClient.request<ProviderServiceDto>(
    path: ServicesApiPaths.providerServices,
    method: RequestMethod.post,
    body: dto.toJson(),
    parser: (data) =>
        ProviderServiceDto.fromJson(data as Map<String, dynamic>),
  );

  @override
  TaskEither<Failure, ProviderServiceDto> updateProviderService(
    String id,
    UpdateProviderServiceDto dto,
  ) => _apiClient.request<ProviderServiceDto>(
    path: ServicesApiPaths.providerService(id),
    method: RequestMethod.patch,
    body: dto.toJson(),
    parser: (data) =>
        ProviderServiceDto.fromJson(data as Map<String, dynamic>),
  );

  @override
  TaskEither<Failure, Unit> deleteProviderService(String id) =>
      _apiClient.request<Unit>(
        path: ServicesApiPaths.providerService(id),
        method: RequestMethod.delete,
        parser: (_) => unit,
      );

  @override
  TaskEither<Failure, ProviderServiceDto> updateProviderServiceStatus(
    String id,
    ProviderServiceStatus status,
  ) => _apiClient.request<ProviderServiceDto>(
    path: ServicesApiPaths.providerServiceStatus(id),
    method: RequestMethod.patch,
    body: UpdateProviderServiceStatusDto(status: status).toJson(),
    parser: (data) =>
        ProviderServiceDto.fromJson(data as Map<String, dynamic>),
  );

  @override
  TaskEither<Failure, ProviderServiceOverviewDto> getOverview() =>
      _apiClient.request<ProviderServiceOverviewDto>(
        path: ServicesApiPaths.providerServicesOverview,
        method: RequestMethod.get,
        parser: (data) =>
            ProviderServiceOverviewDto.fromJson(data as Map<String, dynamic>),
      );

  @override
  TaskEither<Failure, ProviderServiceOverviewDto> getOverviewFor(
    String id,
  ) => _apiClient.request<ProviderServiceOverviewDto>(
    path: ServicesApiPaths.providerServiceOverview(id),
    method: RequestMethod.get,
    parser: (data) =>
        ProviderServiceOverviewDto.fromJson(data as Map<String, dynamic>),
  );

  @override
  TaskEither<Failure, ProviderServiceImageDto> addImage(
    String id,
    String mediaId,
  ) => _apiClient.request<ProviderServiceImageDto>(
    path: ServicesApiPaths.providerServiceImages(id),
    method: RequestMethod.post,
    body: AddProviderServiceImageDto(mediaId: mediaId).toJson(),
    parser: (data) =>
        ProviderServiceImageDto.fromJson(data as Map<String, dynamic>),
  );

  @override
  TaskEither<Failure, Unit> deleteImage(String id, String imageId) =>
      _apiClient.request<Unit>(
        path: ServicesApiPaths.providerServiceImage(id, imageId),
        method: RequestMethod.delete,
        parser: (_) => unit,
      );

  @override
  TaskEither<Failure, ProviderServiceDto> setPrimaryImage(
    String id,
    String imageId,
  ) => _apiClient.request<ProviderServiceDto>(
    path: ServicesApiPaths.providerServiceImagePrimary(id, imageId),
    method: RequestMethod.patch,
    parser: (data) =>
        ProviderServiceDto.fromJson(data as Map<String, dynamic>),
  );
}
