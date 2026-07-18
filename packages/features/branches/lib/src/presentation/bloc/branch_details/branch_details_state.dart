part of 'branch_details_bloc.dart';

class BranchDetailsState extends Equatable {
  const BranchDetailsState({
    this.branchId,
    this.status = RequestStatus.initial,
    this.failure,
    this.branch,
    this.statusUpdateLoading = false,
    this.statusUpdateFailure,
  });

  final String? branchId;
  final RequestStatus status;
  final Failure? failure;
  final BranchEntity? branch;

  /// `true` while PATCH /branches/:id/status is in-flight.
  final bool statusUpdateLoading;
  final Failure? statusUpdateFailure;

  bool get isLoading => status == RequestStatus.loading;
  bool get isSuccess => status == RequestStatus.success;
  bool get hasError => status == RequestStatus.failure;

  BranchDetailsState copyWith({
    String? branchId,
    RequestStatus? status,
    Failure? failure,
    BranchEntity? branch,
    bool clearFailure = false,
    bool? statusUpdateLoading,
    Failure? statusUpdateFailure,
    bool clearStatusUpdateFailure = false,
  }) => BranchDetailsState(
    branchId: branchId ?? this.branchId,
    status: status ?? this.status,
    failure: clearFailure ? null : (failure ?? this.failure),
    branch: branch ?? this.branch,
    statusUpdateLoading: statusUpdateLoading ?? this.statusUpdateLoading,
    statusUpdateFailure: clearStatusUpdateFailure
        ? null
        : (statusUpdateFailure ?? this.statusUpdateFailure),
  );

  @override
  List<Object?> get props => [
    branchId,
    status,
    failure,
    branch,
    statusUpdateLoading,
    statusUpdateFailure,
  ];
}
