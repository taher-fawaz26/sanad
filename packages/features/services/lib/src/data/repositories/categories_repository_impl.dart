import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/data/datasources/services_remote_data_source.dart';
import 'package:services/src/domain/entities/category_record_entity.dart';
import 'package:services/src/domain/entities/pagination_meta_entity.dart';
import 'package:services/src/domain/repositories/categories_repository.dart';

class CategoriesRepositoryImpl implements CategoriesRepository {
  const CategoriesRepositoryImpl(this._remoteDataSource);

  final ServicesRemoteDataSource _remoteDataSource;

  @override
  TaskEither<Failure, ServicesPagedResult<CategoryRecordEntity>> getCategories({
    int page = 1,
    int limit = 10,
    String? search,
  }) => _remoteDataSource
      .getCategories(page: page, limit: limit, search: search)
      .map(
        (paged) => ServicesPagedResult(
          items: paged.items.map((dto) => dto.toEntity()).toList(),
          meta: paged.meta,
        ),
      );
}
