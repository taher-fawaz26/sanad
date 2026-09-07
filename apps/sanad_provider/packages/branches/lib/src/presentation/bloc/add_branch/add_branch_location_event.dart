part of 'add_branch_location_bloc.dart';

sealed class AddBranchLocationEvent extends Equatable {
  const AddBranchLocationEvent();

  @override
  List<Object?> get props => [];
}

final class AddBranchLocationEnsureAccessRequested
    extends AddBranchLocationEvent {
  const AddBranchLocationEnsureAccessRequested();
}

final class AddBranchLocationRefreshed extends AddBranchLocationEvent {
  const AddBranchLocationRefreshed();
}

final class AddBranchLocationRequestAgain extends AddBranchLocationEvent {
  const AddBranchLocationRequestAgain();
}
