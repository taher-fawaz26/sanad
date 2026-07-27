part of 'invitations_list_bloc.dart';

class InvitationsListState extends Equatable {
  const InvitationsListState({
    this.status = RequestStatus.initial,
    this.invitations = const [],
    this.searchQuery = '',
    this.failure,
    this.page = 1,
    this.totalPages = 1,
    this.loadingMore = false,
  });

  final RequestStatus status;
  final List<InvitationEntity> invitations;
  final String searchQuery;
  final Failure? failure;
  final int page;
  final int totalPages;
  final bool loadingMore;

  bool get isLoading => status == RequestStatus.loading;
  bool get hasError => status == RequestStatus.failure;
  bool get hasMore => page < totalPages;

  List<InvitationEntity> get filteredInvitations => invitations;

  InvitationsListState copyWith({
    RequestStatus? status,
    List<InvitationEntity>? invitations,
    String? searchQuery,
    Failure? failure,
    bool clearFailure = false,
    int? page,
    int? totalPages,
    bool? loadingMore,
  }) => InvitationsListState(
    status: status ?? this.status,
    invitations: invitations ?? this.invitations,
    searchQuery: searchQuery ?? this.searchQuery,
    failure: clearFailure ? null : (failure ?? this.failure),
    page: page ?? this.page,
    totalPages: totalPages ?? this.totalPages,
    loadingMore: loadingMore ?? this.loadingMore,
  );

  @override
  List<Object?> get props => [
    status,
    invitations,
    searchQuery,
    failure,
    page,
    totalPages,
    loadingMore,
  ];
}
