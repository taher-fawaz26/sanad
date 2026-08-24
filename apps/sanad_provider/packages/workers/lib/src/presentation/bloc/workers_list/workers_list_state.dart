part of 'workers_list_bloc.dart';

class WorkersListState extends Equatable {
  const WorkersListState({
    this.pagination = const PaginationData<WorkerEntity>(),
    this.searchQuery = '',
    this.statusFilter,
    this.typeFilter,
  });

  final PaginationData<WorkerEntity> pagination;
  final String searchQuery;

  /// `null` means "All" — every status. Applied server-side (see
  /// `WorkersListBloc.buildQuery`), unlike Services' category filter, which
  /// has no server-side equivalent.
  final WorkerStatus? statusFilter;

  /// `null` means "All" — every type. Applied server-side.
  final WorkerType? typeFilter;

  List<WorkerEntity> get workers => pagination.items;

  /// Lists are filtered server-side; alias kept for widget symmetry.
  List<WorkerEntity> get filteredWorkers => workers;

  RequestStatus get status => pagination.status;
  Failure? get failure => pagination.firstPageError;
  int get page => pagination.meta.currentPage;
  int get totalPages => pagination.meta.totalPages;
  bool get loadingMore => pagination.loadingMore;
  bool get isLoading => pagination.isLoadingFirstPage;
  bool get hasError => pagination.hasFirstPageError;
  bool get hasMore => pagination.hasMore;

  WorkersListState copyWith({
    PaginationData<WorkerEntity>? pagination,
    String? searchQuery,
    WorkerStatus? statusFilter,
    bool clearStatusFilter = false,
    WorkerType? typeFilter,
    bool clearTypeFilter = false,
  }) => WorkersListState(
    pagination: pagination ?? this.pagination,
    searchQuery: searchQuery ?? this.searchQuery,
    statusFilter: clearStatusFilter
        ? null
        : (statusFilter ?? this.statusFilter),
    typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
  );

  @override
  List<Object?> get props => [
    pagination,
    searchQuery,
    statusFilter,
    typeFilter,
  ];
}
