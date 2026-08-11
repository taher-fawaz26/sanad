import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/category_record_entity.dart';
import 'package:services/src/domain/entities/pagination_meta_entity.dart';

/// Real `GET /categories` — distinct from the pre-existing, unrelated
/// `ServiceRepository` used by the branches-assignment catalog flow.
abstract interface class CategoriesRepository {
  TaskEither<Failure, ServicesPagedResult<CategoryRecordEntity>> getCategories({
    int page = 1,
    int limit = 10,
    String? search,
  });
}
