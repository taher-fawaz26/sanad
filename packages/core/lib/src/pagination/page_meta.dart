import 'package:equatable/equatable.dart';

/// Generic offset-pagination metadata matching the SANAD backend's
/// `{ data: [...], meta: {...} }` envelope, shared by every paginated
/// endpoint (workers, services, branches, invitations, admin lists, ...).
class PageMeta extends Equatable {
  const PageMeta({
    required this.totalItems,
    required this.itemCount,
    required this.itemsPerPage,
    required this.totalPages,
    required this.currentPage,
  });

  const PageMeta.empty()
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
