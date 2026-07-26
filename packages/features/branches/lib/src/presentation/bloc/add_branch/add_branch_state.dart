part of 'add_branch_bloc.dart';

class AddBranchState extends Equatable {
  const AddBranchState({
    this.status = RequestStatus.initial,
    this.setupStatus = RequestStatus.initial,
    this.loadStatus = RequestStatus.initial,
    this.failure,
    this.setupFailure,
    this.loadFailure,
    this.createdBranch,
    this.loadedBranch,
    this.companySchedule = const [],
  });

  /// Status of the create/update submission.
  final RequestStatus status;

  /// Status of loading the company schedule used as the default branch schedule.
  final RequestStatus setupStatus;

  /// Status of loading an existing branch to prefill the wizard (edit, id-only).
  final RequestStatus loadStatus;

  final Failure? failure;

  /// Failure from the setup fetch (schedule), shown inline.
  final Failure? setupFailure;

  /// Failure from loading the branch to edit, shown inline.
  final Failure? loadFailure;

  /// The branch produced by a successful create/update submission.
  final BranchEntity? createdBranch;

  /// The branch fetched for editing (id-only edit entry), used to seed the draft.
  final BranchEntity? loadedBranch;

  final List<BranchAvailabilityEntity> companySchedule;

  bool get isLoading => status == RequestStatus.loading;
  bool get isSuccess => status == RequestStatus.success;
  bool get hasError => status == RequestStatus.failure;

  bool get isLoadingSetup =>
      setupStatus == RequestStatus.initial ||
      setupStatus == RequestStatus.loading;

  bool get hasSetupError => setupStatus == RequestStatus.failure;

  bool get isLoadingBranch =>
      loadStatus == RequestStatus.initial ||
      loadStatus == RequestStatus.loading;

  bool get hasLoadError => loadStatus == RequestStatus.failure;

  AddBranchState copyWith({
    RequestStatus? status,
    RequestStatus? setupStatus,
    RequestStatus? loadStatus,
    Failure? failure,
    Failure? setupFailure,
    Failure? loadFailure,
    BranchEntity? createdBranch,
    BranchEntity? loadedBranch,
    List<BranchAvailabilityEntity>? companySchedule,
    bool clearFailure = false,
    bool clearSetupFailure = false,
    bool clearLoadFailure = false,
  }) => AddBranchState(
    status: status ?? this.status,
    setupStatus: setupStatus ?? this.setupStatus,
    loadStatus: loadStatus ?? this.loadStatus,
    failure: clearFailure ? null : (failure ?? this.failure),
    setupFailure: clearSetupFailure
        ? null
        : (setupFailure ?? this.setupFailure),
    loadFailure: clearLoadFailure ? null : (loadFailure ?? this.loadFailure),
    createdBranch: createdBranch ?? this.createdBranch,
    loadedBranch: loadedBranch ?? this.loadedBranch,
    companySchedule: companySchedule ?? this.companySchedule,
  );

  @override
  List<Object?> get props => [
    status,
    setupStatus,
    loadStatus,
    failure,
    setupFailure,
    loadFailure,
    createdBranch,
    loadedBranch,
    companySchedule,
  ];
}
