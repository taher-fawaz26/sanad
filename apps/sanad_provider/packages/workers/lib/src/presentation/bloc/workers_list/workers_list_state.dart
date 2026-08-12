part of 'workers_list_bloc.dart';

class WorkersListState extends Equatable {
  const WorkersListState({
    this.pagination = const PaginationData<WorkerEntity>(),
    this.searchQuery = '',
  });

  final PaginationData<WorkerEntity> pagination;
  final String searchQuery;

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
  }) => WorkersListState(
    pagination: pagination ?? this.pagination,
    searchQuery: searchQuery ?? this.searchQuery,
  );

  @override
  List<Object?> get props => [pagination, searchQuery];
}
