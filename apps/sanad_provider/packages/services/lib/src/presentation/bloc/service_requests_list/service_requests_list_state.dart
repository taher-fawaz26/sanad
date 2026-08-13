part of 'service_requests_list_bloc.dart';

class ServiceRequestsListState extends Equatable {
  const ServiceRequestsListState({
    this.pagination = const PaginationData<ServiceRequestEntity>(),
    this.searchQuery = '',
    this.statusFilter = ServiceRequestStatus.all,
  });

  final PaginationData<ServiceRequestEntity> pagination;
  final String searchQuery;
  final ServiceRequestStatus statusFilter;

  List<ServiceRequestEntity> get requests => pagination.items;

  RequestStatus get status => pagination.status;
  Failure? get failure => pagination.firstPageError;
  int get page => pagination.meta.currentPage;
  int get totalPages => pagination.meta.totalPages;
  bool get loadingMore => pagination.loadingMore;
  bool get isLoading => pagination.isLoadingFirstPage;
  bool get hasError => pagination.hasFirstPageError;
  bool get hasMore => pagination.hasMore;

  ServiceRequestsListState copyWith({
    PaginationData<ServiceRequestEntity>? pagination,
    String? searchQuery,
    ServiceRequestStatus? statusFilter,
  }) => ServiceRequestsListState(
    pagination: pagination ?? this.pagination,
    searchQuery: searchQuery ?? this.searchQuery,
    statusFilter: statusFilter ?? this.statusFilter,
  );

  @override
  List<Object?> get props => [pagination, searchQuery, statusFilter];
}
