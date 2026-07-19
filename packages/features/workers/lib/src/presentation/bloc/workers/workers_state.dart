part of 'workers_bloc.dart';

class WorkersState extends Equatable {
  const WorkersState({
    this.status = RequestStatus.initial,
    this.workers = const [],
    this.filteredWorkers = const [],
    this.searchQuery = '',
    this.failure,
    this.actionFailure,
  });

  final RequestStatus status;

  /// All workers loaded from the API (unfiltered).
  final List<WorkerEntity> workers;

  /// Pre-computed result of applying [searchQuery] to [workers].
  final List<WorkerEntity> filteredWorkers;

  final String searchQuery;
  final Failure? failure;

  /// Failure from item actions (delete, status change) — not fetch errors.
  final Failure? actionFailure;

  bool get isLoading => status == RequestStatus.loading;
  bool get isSuccess => status == RequestStatus.success;
  bool get hasError => status == RequestStatus.failure;

  WorkersState copyWith({
    RequestStatus? status,
    List<WorkerEntity>? workers,
    String? searchQuery,
    Failure? failure,
    Failure? actionFailure,
    bool clearFailure = false,
    bool clearActionFailure = false,
  }) {
    final newWorkers = workers ?? this.workers;
    final newQuery = searchQuery ?? this.searchQuery;

    return WorkersState(
      status: status ?? this.status,
      workers: newWorkers,
      filteredWorkers: _applySearch(newWorkers, newQuery),
      searchQuery: newQuery,
      failure: clearFailure ? null : (failure ?? this.failure),
      actionFailure: clearActionFailure
          ? null
          : (actionFailure ?? this.actionFailure),
    );
  }

  @override
  List<Object?> get props => [
    status,
    workers,
    filteredWorkers,
    searchQuery,
    failure,
    actionFailure,
  ];
}

List<WorkerEntity> _applySearch(
  List<WorkerEntity> workers,
  String searchQuery,
) =>
    searchQuery.isEmpty
        ? workers
        : workers
              .where(
                (w) =>
                    w.fullName.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ) ||
                    w.role.toLowerCase().contains(searchQuery.toLowerCase()),
              )
              .toList();
