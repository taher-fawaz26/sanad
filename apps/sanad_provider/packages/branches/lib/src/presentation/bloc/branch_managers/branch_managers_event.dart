part of 'branch_managers_bloc.dart';

sealed class BranchManagersEvent extends Equatable {
  const BranchManagersEvent();

  @override
  List<Object?> get props => [];
}

final class BranchManagersFetchEvent extends BranchManagersEvent {
  const BranchManagersFetchEvent();
}

final class BranchManagersRefreshEvent extends BranchManagersEvent {
  const BranchManagersRefreshEvent();
}

final class BranchManagersLoadMoreEvent extends BranchManagersEvent {
  const BranchManagersLoadMoreEvent();
}

final class BranchManagersSearchChangedEvent extends BranchManagersEvent {
  const BranchManagersSearchChangedEvent(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}
