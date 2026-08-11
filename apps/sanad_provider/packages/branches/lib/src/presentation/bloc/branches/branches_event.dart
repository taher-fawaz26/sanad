part of 'branches_bloc.dart';

sealed class BranchesEvent extends Equatable {
  const BranchesEvent();

  @override
  List<Object?> get props => [];
}

final class BranchesFetchEvent extends BranchesEvent {
  const BranchesFetchEvent();
}

final class BranchesRefreshEvent extends BranchesEvent {
  const BranchesRefreshEvent();
}

final class BranchesFilterChangedEvent extends BranchesEvent {
  const BranchesFilterChangedEvent(this.filter);

  final BranchFilter filter;

  @override
  List<Object?> get props => [filter];
}

final class BranchesSearchChangedEvent extends BranchesEvent {
  const BranchesSearchChangedEvent(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class BranchDeletedEvent extends BranchesEvent {
  const BranchDeletedEvent(this.branchId);

  final String branchId;

  @override
  List<Object?> get props => [branchId];
}

final class BranchStatusChangedEvent extends BranchesEvent {
  const BranchStatusChangedEvent({
    required this.branchId,
    required this.isAvailable,
  });

  final String branchId;

  /// `true` = ACTIVE, `false` = MAINTENANCE.
  final bool isAvailable;

  @override
  List<Object?> get props => [branchId, isAvailable];
}

final class BranchActionFailureClearedEvent extends BranchesEvent {
  const BranchActionFailureClearedEvent();
}
