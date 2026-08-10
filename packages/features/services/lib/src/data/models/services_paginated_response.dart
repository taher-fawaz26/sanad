import 'package:services/src/domain/entities/pagination_meta_entity.dart';

/// Parses the `{data: [...], meta: {totalItems, itemCount, itemsPerPage,
/// totalPages, currentPage}}` envelope shared by `GET /categories`,
/// `GET /services`, and `GET /service-requests/mine`.
ServicesPagedResult<T> parseServicesPage<T>(
  dynamic data,
  T Function(Map<String, dynamic>) itemParser,
) {
  final map = data as Map<String, dynamic>;
  final items = (map['data'] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(itemParser)
      .toList();
  final meta = map['meta'] as Map<String, dynamic>? ?? const {};
  return ServicesPagedResult<T>(
    items: items,
    meta: PaginationMetaEntity(
      totalItems: (meta['totalItems'] as num?)?.toInt() ?? items.length,
      itemCount: (meta['itemCount'] as num?)?.toInt() ?? items.length,
      itemsPerPage: (meta['itemsPerPage'] as num?)?.toInt() ?? items.length,
      totalPages: (meta['totalPages'] as num?)?.toInt() ?? 1,
      currentPage: (meta['currentPage'] as num?)?.toInt() ?? 1,
    ),
  );
}
