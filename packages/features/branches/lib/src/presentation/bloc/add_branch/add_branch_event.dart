part of 'add_branch_bloc.dart';

sealed class AddBranchEvent extends Equatable {
  const AddBranchEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the company schedule used as the default branch availability.
final class AddBranchStarted extends AddBranchEvent {
  const AddBranchStarted();
}

final class AddBranchSubmitEvent extends AddBranchEvent {
  const AddBranchSubmitEvent({required this.params});

  final CreateBranchParams params;

  @override
  List<Object?> get props => [params];
}
