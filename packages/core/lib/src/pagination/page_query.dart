import 'package:equatable/equatable.dart';

/// Default page size used across paginated list endpoints unless a feature
/// has a specific reason to deviate.
const int kDefaultPageLimit = 20;

/// The largest page size any SANAD endpoint accepts.
///
/// The backend caps every paginated route at 100 and answers `400` for `101`
/// or more. Enforced centrally in [PageQuery.toQueryMap] so no individual
/// screen has to remember it, and so a caller that passes a larger `limit`
/// degrades to the maximum instead of failing the request.
const int kMaxPageLimit = 100;

/// Base query for a paginated request. Carries the parameters common to
/// every SANAD paginated endpoint (`page`, `limit`, `search`); feature
/// packages extend this with their own filters (status, categoryId, ...)
/// and merge them into [toQueryMap].
///
/// [kDefaultPageLimit] is only the fallback when a subclass doesn't specify
/// its own default. A feature whose endpoint uses a different page size
/// overrides it on the super-parameter itself, e.g.:
/// ```dart
/// class ProviderServicesQuery extends PageQuery {
///   const ProviderServicesQuery({super.page, super.limit = 10, super.search});
///   ...
/// }
/// ```
/// Either way, an explicit `limit:` argument at any call site always wins.
abstract class PageQuery extends Equatable {
  const PageQuery({this.page = 1, this.limit = kDefaultPageLimit, this.search});

  final int page;
  final int limit;
  final String? search;

  /// Serializes the common params as API query parameters. Subclasses
  /// should call `super.toQueryMap()` and merge in their own filters.
  Map<String, dynamic> toQueryMap() => {
    'page': page,
    'limit': effectiveLimit,
    if (search != null && search!.trim().isNotEmpty) 'search': search!.trim(),
  };

  /// The [limit] actually sent, clamped to [kMaxPageLimit].
  ///
  /// Clamped here rather than in the constructor because every subclass is
  /// `const` — an asserting or normalising constructor would force them all to
  /// become non-const. Reading it (rather than [limit]) is also what makes the
  /// cap impossible to bypass by overriding `toQueryMap` and forgetting it,
  /// since subclasses call `super.toQueryMap()`.
  int get effectiveLimit => limit > kMaxPageLimit ? kMaxPageLimit : limit;

  /// Returns a copy of this query targeting [page], preserving all other
  /// (including feature-specific) fields. Implemented by subclasses since
  /// the concrete return type must be the subclass itself.
  PageQuery copyWithPage(int page);

  @override
  List<Object?> get props => [page, limit, search];
}
