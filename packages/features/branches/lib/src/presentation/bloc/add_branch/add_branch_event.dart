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

/// Submits an edit as a single PATCH (edit mode).
final class UpdateBranchSubmitEvent extends AddBranchEvent {
  const UpdateBranchSubmitEvent({required this.params});

  final UpdateBranchParams params;

  @override
  List<Object?> get props => [params];
}

/// Loads a branch to prefill the wizard when only its id was provided
/// (edit entry without a pre-loaded branch).
final class AddBranchLoadForEditEvent extends AddBranchEvent {
  const AddBranchLoadForEditEvent({required this.branchId});

  final String branchId;

  @override
  List<Object?> get props => [branchId];
}
