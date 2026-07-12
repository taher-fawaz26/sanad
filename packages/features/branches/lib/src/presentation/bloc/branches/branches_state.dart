part of 'branches_bloc.dart';

enum BranchFilter { all, active, maintenance }

class BranchesState extends Equatable {
  const BranchesState({
    this.status = RequestStatus.initial,
    this.branches = const [],
    this.filter = BranchFilter.all,
    this.searchQuery = '',
    this.failure,
    this.meta,
  });

  final RequestStatus status;

  /// All branches loaded from the API (unfiltered).
  final List<BranchEntity> branches;
  final BranchFilter filter;
  final String searchQuery;
  final Failure? failure;
  final BranchPaginationMeta? meta;

  bool get isLoading => status == RequestStatus.loading;
  bool get isSuccess => status == RequestStatus.success;
  bool get hasError => status == RequestStatus.failure;

  /// Client-side filtered and searched list for the current UI state.
  List<BranchEntity> get filteredBranches => branches.where((branch) {
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

  BranchesState copyWith({
    RequestStatus? status,
    List<BranchEntity>? branches,
    BranchFilter? filter,
    String? searchQuery,
    Failure? failure,
    BranchPaginationMeta? meta,
    bool clearFailure = false,
  }) =>
      BranchesState(
        status: status ?? this.status,
        branches: branches ?? this.branches,
        filter: filter ?? this.filter,
        searchQuery: searchQuery ?? this.searchQuery,
        failure: clearFailure ? null : (failure ?? this.failure),
        meta: meta ?? this.meta,
      );

  @override
  List<Object?> get props =>
      [status, branches, filter, searchQuery, failure, meta];
}
