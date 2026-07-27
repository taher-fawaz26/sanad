part of 'workers_list_bloc.dart';

class WorkersListState extends Equatable {
  const WorkersListState({
    this.status = RequestStatus.initial,
    this.workers = const [],
    this.searchQuery = '',
    this.failure,
    this.page = 1,
    this.totalPages = 1,
    this.loadingMore = false,
  });

  final RequestStatus status;
  final List<WorkerEntity> workers;
  final String searchQuery;
  final Failure? failure;
  final int page;
  final int totalPages;
  final bool loadingMore;

  bool get isLoading => status == RequestStatus.loading;
  bool get hasError => status == RequestStatus.failure;
  bool get hasMore => page < totalPages;

  /// Lists are filtered server-side; alias kept for widget symmetry.
  List<WorkerEntity> get filteredWorkers => workers;

  WorkersListState copyWith({
    RequestStatus? status,
    List<WorkerEntity>? workers,
    String? searchQuery,
    Failure? failure,
    bool clearFailure = false,
    int? page,
    int? totalPages,
    bool? loadingMore,
  }) => WorkersListState(
    status: status ?? this.status,
    workers: workers ?? this.workers,
    searchQuery: searchQuery ?? this.searchQuery,
    failure: clearFailure ? null : (failure ?? this.failure),
    page: page ?? this.page,
    totalPages: totalPages ?? this.totalPages,
    loadingMore: loadingMore ?? this.loadingMore,
  );

  @override
  List<Object?> get props => [
    status,
    workers,
    searchQuery,
    failure,
    page,
    totalPages,
    loadingMore,
  ];
}
