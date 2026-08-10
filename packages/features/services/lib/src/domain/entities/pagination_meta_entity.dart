import 'package:equatable/equatable.dart';

/// Offset-pagination metadata shared by the categories, services, and
/// service-requests list endpoints (`{data: [...], meta: {...}}` envelope).
class PaginationMetaEntity extends Equatable {
  const PaginationMetaEntity({
    required this.totalItems,
    required this.itemCount,
    required this.itemsPerPage,
    required this.totalPages,
    required this.currentPage,
  });

  const PaginationMetaEntity.empty()
    : totalItems = 0,
      itemCount = 0,
      itemsPerPage = 0,
      totalPages = 1,
      currentPage = 1;

  final int totalItems;
  final int itemCount;
  final int itemsPerPage;
  final int totalPages;
  final int currentPage;

  bool get hasMore => currentPage < totalPages;

  @override
  List<Object?> get props => [
    totalItems,
    itemCount,
    itemsPerPage,
    totalPages,
    currentPage,
  ];
}

/// Generic paged result for the services feature's list endpoints.
class ServicesPagedResult<T> extends Equatable {
  const ServicesPagedResult({required this.items, required this.meta});

  ServicesPagedResult.empty()
    : items = const [],
      meta = const PaginationMetaEntity.empty();

  final List<T> items;
  final PaginationMetaEntity meta;

  bool get hasMore => meta.hasMore;

  @override
  List<Object?> get props => [items, meta];
}
