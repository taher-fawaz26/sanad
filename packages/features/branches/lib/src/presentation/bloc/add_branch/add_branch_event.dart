part of 'add_branch_bloc.dart';

sealed class AddBranchEvent extends Equatable {
  const AddBranchEvent();

  @override
  List<Object?> get props => [];
}

final class AddBranchSubmitEvent extends AddBranchEvent {
  const AddBranchSubmitEvent({required this.params});

  final CreateBranchParams params;

  @override
  List<Object?> get props => [params];
}
