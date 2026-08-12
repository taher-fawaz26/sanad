import 'package:core/core.dart';

/// Parses the SANAD paginated envelope:
/// `{ data: [...], meta: { totalItems, itemCount, itemsPerPage, totalPages,
/// currentPage } }`, shared verbatim by every paginated SANAD endpoint.
///
/// Pass as the `parser` for `BaseApiClient.request` on any paginated call:
/// `parser: (data) => parsePage(data, WorkerDto.fromJson)`.
Page<T> parsePage<T>(
  dynamic data,
  T Function(Map<String, dynamic> json) itemParser,
) {
  final map = data as Map<String, dynamic>? ?? const {};
  final items = (map['data'] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(itemParser)
      .toList();
  final metaJson = map['meta'] as Map<String, dynamic>?;
  final meta = metaJson == null
      ? const PageMeta.empty()
      : PageMeta(
          totalItems: (metaJson['totalItems'] as num?)?.toInt() ?? 0,
          itemCount: (metaJson['itemCount'] as num?)?.toInt() ?? items.length,
          itemsPerPage: (metaJson['itemsPerPage'] as num?)?.toInt() ?? 0,
          totalPages: (metaJson['totalPages'] as num?)?.toInt() ?? 1,
          currentPage: (metaJson['currentPage'] as num?)?.toInt() ?? 1,
        );
  return Page<T>(items: items, meta: meta);
}
