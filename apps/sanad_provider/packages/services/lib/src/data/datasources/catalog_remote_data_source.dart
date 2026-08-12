import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:services/src/data/endpoints/services_api_paths.dart';
import 'package:services/src/data/models/catalog_service_dto.dart';
import 'package:services/src/data/models/services_paginated_response.dart';
import 'package:services/src/domain/entities/pagination_meta_entity.dart';

/// Master catalog discovery (`GET /services?...`). Read-only — providers
/// browse and select from this, they cannot create catalog services.
abstract interface class CatalogRemoteDataSource {
  TaskEither<Failure, ServicesPagedResult<CatalogServiceDto>> browseCatalog({
    required int page,
    required int limit,
    String? search,
    String? categoryId,
  });
}

class CatalogRemoteDataSourceImpl implements CatalogRemoteDataSource {
  const CatalogRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, ServicesPagedResult<CatalogServiceDto>> browseCatalog({
    required int page,
    required int limit,
    String? search,
    String? categoryId,
  }) => _apiClient.request<ServicesPagedResult<CatalogServiceDto>>(
    path: ServicesApiPaths.catalogServices,
    method: RequestMethod.get,
    query: {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
    },
    parser: (data) => parseServicesPage(data, CatalogServiceDto.fromJson),
  );
}
