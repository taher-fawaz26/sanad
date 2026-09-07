part of 'branches_bloc.dart';

class BranchesState extends Equatable {
  const BranchesState({
    this.pagination = const PaginationData<BranchEntity>(),
    this.filter = BranchFilter.all,
    this.searchQuery = '',
    this.actionFailure,
  });

  final PaginationData<BranchEntity> pagination;
  final BranchFilter filter;
  final String searchQuery;

  /// Failure from list-item actions (status toggle, delete) — not fetch errors.
  final Failure? actionFailure;

  List<BranchEntity> get branches => pagination.items;

  /// Server-side filtering + search now — kept as a distinct accessor so the
  /// UI can lean on the same name it used before, without a client filter
  /// pass on every rebuild.
  List<BranchEntity> get filteredBranches => pagination.items;

  RequestStatus get status => pagination.status;
  Failure? get failure => pagination.firstPageError;
  bool get isLoading => pagination.isLoadingFirstPage;
  bool get isSuccess => pagination.status == RequestStatus.success;
  bool get hasError => pagination.hasFirstPageError;
  bool get hasMore => pagination.hasMore;
  bool get loadingMore => pagination.loadingMore;

  BranchesState copyWith({
    PaginationData<BranchEntity>? pagination,
    BranchFilter? filter,
    String? searchQuery,
    Failure? actionFailure,
    bool clearActionFailure = false,
  }) => BranchesState(
    pagination: pagination ?? this.pagination,
    filter: filter ?? this.filter,
    searchQuery: searchQuery ?? this.searchQuery,
    actionFailure: clearActionFailure
        ? null
        : (actionFailure ?? this.actionFailure),
  );

  @override
  List<Object?> get props => [pagination, filter, searchQuery, actionFailure];
}
