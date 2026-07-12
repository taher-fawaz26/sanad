part of 'add_branch_bloc.dart';

class AddBranchState extends Equatable {
  const AddBranchState({
    this.status = RequestStatus.initial,
    this.failure,
    this.createdBranch,
  });

  final RequestStatus status;
  final Failure? failure;
  final BranchEntity? createdBranch;

  bool get isLoading => status == RequestStatus.loading;
  bool get isSuccess => status == RequestStatus.success;
  bool get hasError => status == RequestStatus.failure;

  AddBranchState copyWith({
    RequestStatus? status,
    Failure? failure,
    BranchEntity? createdBranch,
    bool clearFailure = false,
  }) =>
      AddBranchState(
        status: status ?? this.status,
        failure: clearFailure ? null : (failure ?? this.failure),
        createdBranch: createdBranch ?? this.createdBranch,
      );

  @override
  List<Object?> get props => [status, failure, createdBranch];
}
