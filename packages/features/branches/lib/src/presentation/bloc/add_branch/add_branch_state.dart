part of 'add_branch_bloc.dart';

class AddBranchState extends Equatable {
  const AddBranchState({
    this.status = RequestStatus.initial,
    this.setupStatus = RequestStatus.initial,
    this.failure,
    this.setupFailure,
    this.createdBranch,
    this.companySchedule = const [],
    this.managers = const [],
  });

  /// Status of the create-branch submission.
  final RequestStatus status;

  /// Status of loading the form's supporting data (schedule + managers).
  final RequestStatus setupStatus;

  final Failure? failure;

  /// Failure from the setup fetch (schedule / managers), shown inline.
  final Failure? setupFailure;

  final BranchEntity? createdBranch;
  final List<BranchAvailabilityEntity> companySchedule;
  final List<BranchManagerEntity> managers;

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
    List<BranchManagerEntity>? managers,
    bool clearFailure = false,
    bool clearSetupFailure = false,
  }) =>
      AddBranchState(
        status: status ?? this.status,
        setupStatus: setupStatus ?? this.setupStatus,
        failure: clearFailure ? null : (failure ?? this.failure),
        setupFailure:
            clearSetupFailure ? null : (setupFailure ?? this.setupFailure),
        createdBranch: createdBranch ?? this.createdBranch,
        companySchedule: companySchedule ?? this.companySchedule,
        managers: managers ?? this.managers,
      );

  @override
  List<Object?> get props => [
        status,
        setupStatus,
        failure,
        setupFailure,
        createdBranch,
        companySchedule,
        managers,
      ];
}
