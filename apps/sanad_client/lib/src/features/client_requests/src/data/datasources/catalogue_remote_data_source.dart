import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:sanad_client/src/features/client_requests/src/data/endpoints/catalogue_api_paths.dart';
import 'package:sanad_client/src/features/client_requests/src/data/models/catalogue_dtos.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/repositories/catalogue_repository.dart';

/// Reads the public service catalogue.
abstract interface class CatalogueRemoteDataSource {
  /// `GET /services`.
  TaskEither<Failure, Page<CatalogueServiceDto>> services(CatalogueQuery query);

  /// `GET /categories`.
  TaskEither<Failure, Page<CatalogueCategoryDto>> categories(
    CatalogueQuery query,
  );
}

/// Dio-backed [CatalogueRemoteDataSource].
class CatalogueRemoteDataSourceImpl implements CatalogueRemoteDataSource {
  /// Creates the data source.
  const CatalogueRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, Page<CatalogueServiceDto>> services(
    CatalogueQuery query,
  ) => _apiClient.request<Page<CatalogueServiceDto>>(
    path: CatalogueApiPaths.services,
    method: RequestMethod.get,
    query: query.toQueryMap(),
    parser: (data) => parsePage(data, CatalogueServiceDto.fromJson),
  );

  @override
  TaskEither<Failure, Page<CatalogueCategoryDto>> categories(
    CatalogueQuery query,
  ) => _apiClient.request<Page<CatalogueCategoryDto>>(
    path: CatalogueApiPaths.categories,
    method: RequestMethod.get,
    query: query.toQueryMap(),
    parser: (data) => parsePage(data, CatalogueCategoryDto.fromJson),
  );
}
