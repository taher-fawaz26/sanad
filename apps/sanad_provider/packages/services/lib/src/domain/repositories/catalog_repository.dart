import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/catalog_service_entity.dart';
import 'package:services/src/domain/entities/pagination_meta_entity.dart';

abstract interface class CatalogRepository {
  TaskEither<Failure, ServicesPagedResult<CatalogServiceEntity>>
  browseCatalog({
    int page = 1,
    int limit = 10,
    String? search,
    String? categoryId,
  });
}
