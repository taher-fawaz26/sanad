part of 'branch_managers_bloc.dart';

class BranchManagersState extends Equatable {
  const BranchManagersState({
    this.pagination = const PaginationData<BranchManagerEntity>(),
    this.searchQuery = '',
  });

  final PaginationData<BranchManagerEntity> pagination;
  final String searchQuery;

  List<BranchManagerEntity> get managers => pagination.items;
  RequestStatus get status => pagination.status;
  bool get isLoadingFirstPage => pagination.isLoadingFirstPage;
  bool get loadingMore => pagination.loadingMore;
  bool get hasMore => pagination.hasMore;
  bool get isEmpty => pagination.isEmpty;
  Failure? get firstPageError => pagination.firstPageError;
  Failure? get nextPageError => pagination.nextPageError;

  BranchManagersState copyWith({
    PaginationData<BranchManagerEntity>? pagination,
    String? searchQuery,
  }) => BranchManagersState(
    pagination: pagination ?? this.pagination,
    searchQuery: searchQuery ?? this.searchQuery,
  );

  @override
  List<Object?> get props => [pagination, searchQuery];
}
