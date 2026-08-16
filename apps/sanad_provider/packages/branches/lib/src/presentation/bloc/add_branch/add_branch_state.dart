part of 'add_branch_bloc.dart';

class AddBranchState extends Equatable {
  const AddBranchState({
    this.status = RequestStatus.initial,
    this.setupStatus = RequestStatus.initial,
    this.failure,
    this.setupFailure,
    this.createdBranch,
    this.companySchedule = const [],
  });

  /// Status of the create submission.
  final RequestStatus status;

  /// Status of loading the company schedule used as the default branch schedule.
  final RequestStatus setupStatus;

  final Failure? failure;

  /// Failure from the setup fetch (schedule), shown inline.
  final Failure? setupFailure;

  /// The branch produced by a successful create submission.
  final BranchEntity? createdBranch;

  final List<BranchAvailabilityEntity> companySchedule;

  bool get isLoading => status == RequestStatus.loading;
  bool get isSuccess => status == RequestStatus.success;
  bool get hasError => status == RequestStatus.failure;

  bool get isLoadingSetup =>
      setupStatus == RequestStatus.initial ||
      setupStatus == RequestStatus.loading;

  bool get hasSetupError => setupStatus == RequestStatus.failure;

  AddBranchState copyWith({
    RequestStatus? status,
    RequestStatus? setupStatus,
    Failure? failure,
    Failure? setupFailure,
    BranchEntity? createdBranch,
    List<BranchAvailabilityEntity>? companySchedule,
    bool clearFailure = false,
    bool clearSetupFailure = false,
  }) => AddBranchState(
    status: status ?? this.status,
    setupStatus: setupStatus ?? this.setupStatus,
    failure: clearFailure ? null : (failure ?? this.failure),
    setupFailure: clearSetupFailure
        ? null
        : (setupFailure ?? this.setupFailure),
    createdBranch: createdBranch ?? this.createdBranch,
    companySchedule: companySchedule ?? this.companySchedule,
  );

  @override
  List<Object?> get props => [
    status,
    setupStatus,
    failure,
    setupFailure,
    createdBranch,
    companySchedule,
  ];
}
