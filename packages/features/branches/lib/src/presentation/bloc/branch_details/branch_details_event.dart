part of 'branch_details_bloc.dart';

sealed class BranchDetailsEvent extends Equatable {
  const BranchDetailsEvent();

  @override
  List<Object?> get props => [];
}

final class BranchDetailsFetchEvent extends BranchDetailsEvent {
  const BranchDetailsFetchEvent(this.branchId);

  final String branchId;

  @override
  List<Object?> get props => [branchId];
}

final class BranchDetailsRefreshEvent extends BranchDetailsEvent {
  const BranchDetailsRefreshEvent();
}
