part of 'workers_bloc.dart';

class WorkersState extends Equatable {
  const WorkersState({
    this.status = RequestStatus.initial,
    this.workers = const [],
    this.searchQuery = '',
    this.failure,
    this.actionFailure,
    this.selectedTab = 0,
    this.invitations = const [],
    this.invitationsStatus = RequestStatus.initial,
    this.workersPage = 1,
    this.workersTotalPages = 1,
    this.workersLoadingMore = false,
    this.invitationsPage = 1,
    this.invitationsTotalPages = 1,
    this.invitationsLoadingMore = false,
  });

  final RequestStatus status;
  final List<WorkerEntity> workers;
  final String searchQuery;
  final Failure? failure;
  final Failure? actionFailure;

  final int selectedTab;
  final List<InvitationEntity> invitations;
  final RequestStatus invitationsStatus;

  // Offset-pagination cursors (server-side).
  final int workersPage;
  final int workersTotalPages;
  final bool workersLoadingMore;
  final int invitationsPage;
  final int invitationsTotalPages;
  final bool invitationsLoadingMore;

  bool get isLoading => status == RequestStatus.loading;
  bool get isSuccess => status == RequestStatus.success;
  bool get hasError => status == RequestStatus.failure;

  bool get isTeamTab => selectedTab == 0;
  bool get isInvitationsTab => selectedTab == 1;

  bool get workersHasMore => workersPage < workersTotalPages;
  bool get invitationsHasMore => invitationsPage < invitationsTotalPages;

  /// Lists are filtered server-side; these aliases keep the page widgets
  /// unchanged.
  List<WorkerEntity> get filteredWorkers => workers;
  List<InvitationEntity> get filteredInvitations => invitations;

  WorkersState copyWith({
    RequestStatus? status,
    List<WorkerEntity>? workers,
    String? searchQuery,
    Failure? failure,
    Failure? actionFailure,
    bool clearFailure = false,
    bool clearActionFailure = false,
    int? selectedTab,
    List<InvitationEntity>? invitations,
    RequestStatus? invitationsStatus,
    int? workersPage,
    int? workersTotalPages,
    bool? workersLoadingMore,
    int? invitationsPage,
    int? invitationsTotalPages,
    bool? invitationsLoadingMore,
  }) {
    return WorkersState(
      status: status ?? this.status,
      workers: workers ?? this.workers,
      searchQuery: searchQuery ?? this.searchQuery,
      failure: clearFailure ? null : (failure ?? this.failure),
      actionFailure: clearActionFailure
          ? null
          : (actionFailure ?? this.actionFailure),
      selectedTab: selectedTab ?? this.selectedTab,
      invitations: invitations ?? this.invitations,
      invitationsStatus: invitationsStatus ?? this.invitationsStatus,
      workersPage: workersPage ?? this.workersPage,
      workersTotalPages: workersTotalPages ?? this.workersTotalPages,
      workersLoadingMore: workersLoadingMore ?? this.workersLoadingMore,
      invitationsPage: invitationsPage ?? this.invitationsPage,
      invitationsTotalPages:
          invitationsTotalPages ?? this.invitationsTotalPages,
      invitationsLoadingMore:
          invitationsLoadingMore ?? this.invitationsLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
    status,
    workers,
    searchQuery,
    failure,
    actionFailure,
    selectedTab,
    invitations,
    invitationsStatus,
    workersPage,
    workersTotalPages,
    workersLoadingMore,
    invitationsPage,
    invitationsTotalPages,
    invitationsLoadingMore,
  ];
}
