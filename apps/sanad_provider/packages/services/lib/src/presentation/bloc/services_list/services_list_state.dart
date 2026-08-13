part of 'services_list_bloc.dart';

class ServicesListState extends Equatable {
  const ServicesListState({
    this.pagination = const PaginationData<ProviderServiceEntity>(),
    this.searchQuery = '',
    this.statusFilter = ProviderServiceStatus.all,
  });

  final PaginationData<ProviderServiceEntity> pagination;
  final String searchQuery;
  final ProviderServiceStatus statusFilter;

  List<ProviderServiceEntity> get services => pagination.items;

  RequestStatus get status => pagination.status;
  Failure? get failure => pagination.firstPageError;
  int get page => pagination.meta.currentPage;
  int get totalPages => pagination.meta.totalPages;
  bool get loadingMore => pagination.loadingMore;
  bool get isLoading => pagination.isLoadingFirstPage;
  bool get hasError => pagination.hasFirstPageError;
  bool get hasMore => pagination.hasMore;

  ServicesListState copyWith({
    PaginationData<ProviderServiceEntity>? pagination,
    String? searchQuery,
    ProviderServiceStatus? statusFilter,
  }) => ServicesListState(
    pagination: pagination ?? this.pagination,
    searchQuery: searchQuery ?? this.searchQuery,
    statusFilter: statusFilter ?? this.statusFilter,
  );

  @override
  List<Object?> get props => [pagination, searchQuery, statusFilter];
}
