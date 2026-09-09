import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/catalogue_entities.dart';

/// Query for the public catalogue endpoints.
class CatalogueQuery extends PageQuery {
  /// Creates a catalogue query.
  const CatalogueQuery({
    super.page,
    super.limit,
    super.search,
    this.categoryId,
  });

  /// Narrows to one category.
  final String? categoryId;

  @override
  Map<String, dynamic> toQueryMap() => {
    ...super.toQueryMap(),
    if (categoryId != null) 'categoryId': categoryId,
  };

  @override
  CatalogueQuery copyWithPage(int page) => CatalogueQuery(
    page: page,
    limit: limit,
    search: search,
    categoryId: categoryId,
  );

  @override
  List<Object?> get props => [...super.props, categoryId];
}

/// Read-only access to the public service catalogue, which is where a draft's
/// `serviceId` comes from.
abstract interface class CatalogueRepository {
  /// `GET /services` — the catalogue a draft picks its service from.
  TaskEither<Failure, Page<CatalogueService>> services(CatalogueQuery query);

  /// `GET /categories` — for grouping the service picker.
  TaskEither<Failure, Page<CatalogueCategory>> categories(CatalogueQuery query);
}
