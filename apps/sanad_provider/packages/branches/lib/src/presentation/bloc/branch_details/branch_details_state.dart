part of 'branch_details_bloc.dart';

class BranchDetailsState extends Equatable {
  const BranchDetailsState({
    this.branchId,
    this.status = RequestStatus.initial,
    this.failure,
    this.branch,
    this.companySchedule,
    this.statusUpdateLoading = false,
    this.statusUpdateFailure,
    this.sectionSaveStatus = RequestStatus.initial,
    this.sectionSaveFailure,
  });

  final String? branchId;
  final RequestStatus status;
  final Failure? failure;
  final BranchEntity? branch;

  /// Org-wide company working hours, fetched lazily for company-hours
  /// branches whose own [BranchEntity.availability] is empty (the effective
  /// schedule lives here, not on the branch payload). `null` until fetched.
  /// Used so the details view renders real hours instead of showing every
  /// day as closed (SAN-780).
  final List<BranchAvailabilityEntity>? companySchedule;

  /// `true` while PATCH /branches/:id/status is in-flight.
  final bool statusUpdateLoading;
  final Failure? statusUpdateFailure;

  /// Status of the in-flight section edit (PATCH + rehydrating re-fetch),
  /// kept separate from [status] so a section save never blanks the screen.
  final RequestStatus sectionSaveStatus;
  final Failure? sectionSaveFailure;

  bool get isLoading => status == RequestStatus.loading;
  bool get isSuccess => status == RequestStatus.success;
  bool get hasError => status == RequestStatus.failure;

  bool get isSectionSaveLoading => sectionSaveStatus == RequestStatus.loading;
  bool get isSectionSaveSuccess => sectionSaveStatus == RequestStatus.success;

  BranchDetailsState copyWith({
    String? branchId,
    RequestStatus? status,
    Failure? failure,
    BranchEntity? branch,
    List<BranchAvailabilityEntity>? companySchedule,
    bool clearFailure = false,
    bool? statusUpdateLoading,
    Failure? statusUpdateFailure,
    bool clearStatusUpdateFailure = false,
    RequestStatus? sectionSaveStatus,
    Failure? sectionSaveFailure,
    bool clearSectionSaveFailure = false,
  }) => BranchDetailsState(
    branchId: branchId ?? this.branchId,
    status: status ?? this.status,
    failure: clearFailure ? null : (failure ?? this.failure),
    branch: branch ?? this.branch,
    companySchedule: companySchedule ?? this.companySchedule,
    statusUpdateLoading: statusUpdateLoading ?? this.statusUpdateLoading,
    statusUpdateFailure: clearStatusUpdateFailure
        ? null
        : (statusUpdateFailure ?? this.statusUpdateFailure),
    sectionSaveStatus: sectionSaveStatus ?? this.sectionSaveStatus,
    sectionSaveFailure: clearSectionSaveFailure
        ? null
        : (sectionSaveFailure ?? this.sectionSaveFailure),
  );

  @override
  List<Object?> get props => [
    branchId,
    status,
    failure,
    branch,
    companySchedule,
    statusUpdateLoading,
    statusUpdateFailure,
    sectionSaveStatus,
    sectionSaveFailure,
  ];
}
