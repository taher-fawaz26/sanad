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
