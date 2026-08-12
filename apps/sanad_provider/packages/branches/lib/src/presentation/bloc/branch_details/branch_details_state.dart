part of 'branch_details_bloc.dart';

class BranchDetailsState extends Equatable {
  const BranchDetailsState({
    this.branchId,
    this.status = RequestStatus.initial,
    this.failure,
    this.branch,
    this.statusUpdateLoading = false,
    this.statusUpdateFailure,
    this.sectionSaveStatus = RequestStatus.initial,
    this.sectionSaveFailure,
  });

  final String? branchId;
  final RequestStatus status;
  final Failure? failure;
  final BranchEntity? branch;

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
    statusUpdateLoading,
    statusUpdateFailure,
    sectionSaveStatus,
    sectionSaveFailure,
  ];
}
