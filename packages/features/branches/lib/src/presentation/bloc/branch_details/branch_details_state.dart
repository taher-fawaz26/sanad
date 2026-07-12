part of 'branch_details_bloc.dart';

class BranchDetailsState extends Equatable {
  const BranchDetailsState({
    this.branchId,
    this.status = RequestStatus.initial,
    this.failure,
    this.branch,
  });

  final String? branchId;
  final RequestStatus status;
  final Failure? failure;
  final BranchEntity? branch;

  bool get isLoading => status == RequestStatus.loading;
  bool get isSuccess => status == RequestStatus.success;
  bool get hasError => status == RequestStatus.failure;

  BranchDetailsState copyWith({
    String? branchId,
    RequestStatus? status,
    Failure? failure,
    BranchEntity? branch,
    bool clearFailure = false,
  }) =>
      BranchDetailsState(
        branchId: branchId ?? this.branchId,
        status: status ?? this.status,
        failure: clearFailure ? null : (failure ?? this.failure),
        branch: branch ?? this.branch,
      );

  @override
  List<Object?> get props => [branchId, status, failure, branch];
}
