part of 'branches_bloc.dart';

enum BranchFilter { all, active, maintenance }

class BranchesState extends Equatable {
  const BranchesState({
    this.status = RequestStatus.initial,
    this.branches = const [],
    this.filteredBranches = const [],
    this.filter = BranchFilter.all,
    this.searchQuery = '',
    this.failure,
    this.actionFailure,
    this.meta,
  });

  final RequestStatus status;

  /// All branches loaded from the API (unfiltered).
  final List<BranchEntity> branches;

  /// Pre-computed result of applying [filter] and [searchQuery] to [branches].
  /// Computed once per state change — not recalculated on every rebuild.
  final List<BranchEntity> filteredBranches;

  final BranchFilter filter;
  final String searchQuery;
  final Failure? failure;

  /// Failure from list-item actions (status toggle, delete) — not fetch errors.
  final Failure? actionFailure;

  final BranchPaginationMeta? meta;

  bool get isLoading => status == RequestStatus.loading;
  bool get isSuccess => status == RequestStatus.success;
  bool get hasError => status == RequestStatus.failure;

  BranchesState copyWith({
    RequestStatus? status,
    List<BranchEntity>? branches,
    BranchFilter? filter,
    String? searchQuery,
    Failure? failure,
    Failure? actionFailure,
    BranchPaginationMeta? meta,
    bool clearFailure = false,
    bool clearActionFailure = false,
  }) {
    final newBranches = branches ?? this.branches;
    final newFilter = filter ?? this.filter;
    final newQuery = searchQuery ?? this.searchQuery;

    return BranchesState(
      status: status ?? this.status,
      branches: newBranches,
      filteredBranches: _applyFilter(newBranches, newFilter, newQuery),
      filter: newFilter,
      searchQuery: newQuery,
      failure: clearFailure ? null : (failure ?? this.failure),
      actionFailure:
          clearActionFailure ? null : (actionFailure ?? this.actionFailure),
      meta: meta ?? this.meta,
    );
  }

  @override
  List<Object?> get props => [
        status,
        branches,
        filteredBranches,
        filter,
        searchQuery,
        failure,
        actionFailure,
        meta,
      ];
}

List<BranchEntity> _applyFilter(
  List<BranchEntity> branches,
  BranchFilter filter,
  String searchQuery,
) =>
    branches.where((branch) {
      final matchesSearch = searchQuery.isEmpty ||
          branch.branchName
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ||
          branch.city.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesFilter = switch (filter) {
        BranchFilter.all => true,
        BranchFilter.active => branch.isAvailable,
        BranchFilter.maintenance => !branch.isAvailable,
      };

      return matchesSearch && matchesFilter;
    }).toList();
