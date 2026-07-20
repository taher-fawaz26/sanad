import 'package:workers/src/domain/entities/paged_result.dart';

/// Parses the SANAD paginated envelope:
/// `{ data: [...], meta: { currentPage, totalPages, ... } }`.
///
/// The shared `network.PaginatedResponse` uses a different shape
/// (`items/total/page/page_size`), so this is SANAD-specific.
PagedResult<T> parseSanadPage<T>(
  dynamic data,
  T Function(Map<String, dynamic>) itemParser,
) {
  final map = data as Map<String, dynamic>;
  final items = (map['data'] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(itemParser)
      .toList();
  final meta = map['meta'] as Map<String, dynamic>? ?? const {};
  return PagedResult<T>(
    items: items,
    currentPage: (meta['currentPage'] as num?)?.toInt() ?? 1,
    totalPages: (meta['totalPages'] as num?)?.toInt() ?? 1,
  );
}
