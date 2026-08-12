import 'package:equatable/equatable.dart';

/// Default page size used across paginated list endpoints unless a feature
/// has a specific reason to deviate.
const int kDefaultPageLimit = 20;

/// Base query for a paginated request. Carries the parameters common to
/// every SANAD paginated endpoint (`page`, `limit`, `search`); feature
/// packages extend this with their own filters (status, categoryId, ...)
/// and merge them into [toQueryMap].
abstract class PageQuery extends Equatable {
  const PageQuery({this.page = 1, this.limit = kDefaultPageLimit, this.search});

  final int page;
  final int limit;
  final String? search;

  /// Serializes the common params as API query parameters. Subclasses
  /// should call `super.toQueryMap()` and merge in their own filters.
  Map<String, dynamic> toQueryMap() => {
    'page': page,
    'limit': limit,
    if (search != null && search!.trim().isNotEmpty) 'search': search!.trim(),
  };

  /// Returns a copy of this query targeting [page], preserving all other
  /// (including feature-specific) fields. Implemented by subclasses since
  /// the concrete return type must be the subclass itself.
  PageQuery copyWithPage(int page);

  @override
  List<Object?> get props => [page, limit, search];
}
