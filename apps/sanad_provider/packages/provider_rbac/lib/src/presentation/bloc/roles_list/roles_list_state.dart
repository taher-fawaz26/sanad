part of 'roles_list_bloc.dart';

class RolesListState extends Equatable {
  const RolesListState({
    this.pagination = const PaginationData<RoleEntity>(),
    this.searchQuery = '',
  });

  final PaginationData<RoleEntity> pagination;
  final String searchQuery;

  List<RoleEntity> get roles => pagination.items;

  RequestStatus get status => pagination.status;
  Failure? get failure => pagination.firstPageError;
  bool get isLoading => pagination.isLoadingFirstPage;
  bool get hasError => pagination.hasFirstPageError;
  bool get isEmpty => pagination.isEmpty;
  bool get loadingMore => pagination.loadingMore;
  bool get hasMore => pagination.hasMore;

  RolesListState copyWith({
    PaginationData<RoleEntity>? pagination,
    String? searchQuery,
  }) => RolesListState(
    pagination: pagination ?? this.pagination,
    searchQuery: searchQuery ?? this.searchQuery,
  );

  @override
  List<Object?> get props => [pagination, searchQuery];
}
