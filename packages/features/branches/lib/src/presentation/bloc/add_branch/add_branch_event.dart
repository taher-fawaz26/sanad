part of 'add_branch_bloc.dart';

sealed class AddBranchEvent extends Equatable {
  const AddBranchEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the data the add-branch form depends on (company schedule + the
/// list of assignable managers).
final class AddBranchStarted extends AddBranchEvent {
  const AddBranchStarted();
}

final class AddBranchSubmitEvent extends AddBranchEvent {
  const AddBranchSubmitEvent({required this.params});

  final CreateBranchParams params;

  @override
  List<Object?> get props => [params];
}
