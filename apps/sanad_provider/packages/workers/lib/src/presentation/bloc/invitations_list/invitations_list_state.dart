part of 'invitations_list_bloc.dart';

class InvitationsListState extends Equatable {
  const InvitationsListState({
    this.pagination = const PaginationData<InvitationEntity>(),
    this.searchQuery = '',
  });

  final PaginationData<InvitationEntity> pagination;
  final String searchQuery;

  List<InvitationEntity> get invitations => pagination.items;

  /// Lists are filtered server-side; alias kept for widget symmetry.
  List<InvitationEntity> get filteredInvitations => invitations;

  RequestStatus get status => pagination.status;
  Failure? get failure => pagination.firstPageError;
  int get page => pagination.meta.currentPage;
  int get totalPages => pagination.meta.totalPages;
  bool get loadingMore => pagination.loadingMore;
  bool get isLoading => pagination.isLoadingFirstPage;
  bool get hasError => pagination.hasFirstPageError;
  bool get hasMore => pagination.hasMore;

  InvitationsListState copyWith({
    PaginationData<InvitationEntity>? pagination,
    String? searchQuery,
  }) => InvitationsListState(
    pagination: pagination ?? this.pagination,
    searchQuery: searchQuery ?? this.searchQuery,
  );

  @override
  List<Object?> get props => [pagination, searchQuery];
}
