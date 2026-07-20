part of 'workers_bloc.dart';

class WorkersState extends Equatable {
  const WorkersState({
    this.status = RequestStatus.initial,
    this.workers = const [],
    this.filteredWorkers = const [],
    this.searchQuery = '',
    this.failure,
    this.actionFailure,
    this.selectedTab = 0,
    this.invitations = const [],
    this.filteredInvitations = const [],
    this.invitationsStatus = RequestStatus.initial,
  });

  final RequestStatus status;
  final List<WorkerEntity> workers;
  final List<WorkerEntity> filteredWorkers;
  final String searchQuery;
  final Failure? failure;
  final Failure? actionFailure;

  final int selectedTab;
  final List<InvitationEntity> invitations;
  final List<InvitationEntity> filteredInvitations;
  final RequestStatus invitationsStatus;

  bool get isLoading => status == RequestStatus.loading;
  bool get isSuccess => status == RequestStatus.success;
  bool get hasError => status == RequestStatus.failure;

  bool get isTeamTab => selectedTab == 0;
  bool get isInvitationsTab => selectedTab == 1;

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
  }) {
    final newWorkers = workers ?? this.workers;
    final newInvitations = invitations ?? this.invitations;
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
      selectedTab: selectedTab ?? this.selectedTab,
      invitations: newInvitations,
      filteredInvitations: _applyInvitationSearch(newInvitations, newQuery),
      invitationsStatus: invitationsStatus ?? this.invitationsStatus,
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
    selectedTab,
    invitations,
    filteredInvitations,
    invitationsStatus,
  ];
}

List<WorkerEntity> _applySearch(
  List<WorkerEntity> workers,
  String searchQuery,
) => searchQuery.isEmpty
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

List<InvitationEntity> _applyInvitationSearch(
  List<InvitationEntity> invitations,
  String searchQuery,
) => searchQuery.isEmpty
    ? invitations
    : invitations
          .where(
            (i) =>
                i.fullName.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
                i.role.toLowerCase().contains(searchQuery.toLowerCase()),
          )
          .toList();
