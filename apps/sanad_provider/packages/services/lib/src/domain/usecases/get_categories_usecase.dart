import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/category_record_entity.dart';
import 'package:services/src/domain/entities/pagination_meta_entity.dart';
import 'package:services/src/domain/repositories/categories_repository.dart';

class GetCategoriesParams extends Equatable {
  const GetCategoriesParams({this.page = 1, this.limit = 10, this.search});

  final int page;
  final int limit;
  final String? search;

  @override
  List<Object?> get props => [page, limit, search];
}

class GetCategoriesUseCase
    implements
        UseCase<
          ServicesPagedResult<CategoryRecordEntity>,
          GetCategoriesParams
        > {
  const GetCategoriesUseCase(this._repository);

  final CategoriesRepository _repository;

  @override
  TaskEither<Failure, ServicesPagedResult<CategoryRecordEntity>> call(
    GetCategoriesParams params,
  ) => _repository.getCategories(
    page: params.page,
    limit: params.limit,
    search: params.search,
  );
}
