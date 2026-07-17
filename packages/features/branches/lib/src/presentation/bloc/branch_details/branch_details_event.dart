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

/// Toggles the branch status between ACTIVE ↔ MAINTENANCE.
final class BranchStatusToggleEvent extends BranchDetailsEvent {
  const BranchStatusToggleEvent({required this.isAvailable});

  /// The desired new state: `true` = ACTIVE, `false` = MAINTENANCE.
  final bool isAvailable;

  @override
  List<Object?> get props => [isAvailable];
}
