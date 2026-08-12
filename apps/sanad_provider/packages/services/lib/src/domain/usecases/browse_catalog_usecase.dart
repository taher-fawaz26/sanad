import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/catalog_service_entity.dart';
import 'package:services/src/domain/entities/pagination_meta_entity.dart';
import 'package:services/src/domain/repositories/catalog_repository.dart';

class BrowseCatalogParams extends Equatable {
  const BrowseCatalogParams({
    this.page = 1,
    this.limit = 10,
    this.search,
    this.categoryId,
  });

  final int page;
  final int limit;
  final String? search;
  final String? categoryId;

  @override
  List<Object?> get props => [page, limit, search, categoryId];
}

class BrowseCatalogUseCase
    implements
        UseCase<
          ServicesPagedResult<CatalogServiceEntity>,
          BrowseCatalogParams
        > {
  const BrowseCatalogUseCase(this._repository);

  final CatalogRepository _repository;

  @override
  TaskEither<Failure, ServicesPagedResult<CatalogServiceEntity>> call(
    BrowseCatalogParams params,
  ) => _repository.browseCatalog(
    page: params.page,
    limit: params.limit,
    search: params.search,
    categoryId: params.categoryId,
  );
}
