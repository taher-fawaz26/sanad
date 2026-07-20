import 'package:equatable/equatable.dart';

/// Offset-paginated result matching the SANAD `{data, meta}` envelope.
class PagedResult<T> extends Equatable {
  const PagedResult({
    required this.items,
    required this.currentPage,
    required this.totalPages,
  });

  const PagedResult.empty() : items = const [], currentPage = 1, totalPages = 1;

  final List<T> items;
  final int currentPage;
  final int totalPages;

  bool get hasMore => currentPage < totalPages;

  @override
  List<Object?> get props => [items, currentPage, totalPages];
}
