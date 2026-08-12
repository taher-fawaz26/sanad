import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/data/datasources/catalog_remote_data_source.dart';
import 'package:services/src/domain/entities/catalog_service_entity.dart';
import 'package:services/src/domain/entities/pagination_meta_entity.dart';
import 'package:services/src/domain/repositories/catalog_repository.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  const CatalogRepositoryImpl(this._remoteDataSource);

  final CatalogRemoteDataSource _remoteDataSource;

  @override
  TaskEither<Failure, ServicesPagedResult<CatalogServiceEntity>>
  browseCatalog({
    int page = 1,
    int limit = 10,
    String? search,
    String? categoryId,
  }) => _remoteDataSource
      .browseCatalog(
        page: page,
        limit: limit,
        search: search,
        categoryId: categoryId,
      )
      .map(
        (paged) => ServicesPagedResult(
          items: paged.items.map((dto) => dto.toEntity()).toList(),
          meta: paged.meta,
        ),
      );
}
