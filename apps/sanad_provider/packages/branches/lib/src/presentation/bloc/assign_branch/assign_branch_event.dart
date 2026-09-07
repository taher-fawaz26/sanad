part of 'assign_branch_bloc.dart';

sealed class AssignBranchEvent extends Equatable {
  const AssignBranchEvent();

  @override
  List<Object?> get props => [];
}

final class AssignBranchLoadEvent extends AssignBranchEvent {
  const AssignBranchLoadEvent();
}

final class AssignBranchSelectedEvent extends AssignBranchEvent {
  const AssignBranchSelectedEvent(this.branch);

  final BranchEntity branch;

  @override
  List<Object?> get props => [branch];
}

final class AssignBranchSubmitEvent extends AssignBranchEvent {
  const AssignBranchSubmitEvent();
}
