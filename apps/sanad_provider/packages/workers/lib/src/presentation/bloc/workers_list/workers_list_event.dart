part of 'workers_list_bloc.dart';

sealed class WorkersListEvent extends Equatable {
  const WorkersListEvent();

  @override
  List<Object?> get props => [];
}

final class WorkersListFetchEvent extends WorkersListEvent {
  const WorkersListFetchEvent();
}

final class WorkersListRefreshEvent extends WorkersListEvent {
  const WorkersListRefreshEvent();
}

final class WorkersListLoadMoreEvent extends WorkersListEvent {
  const WorkersListLoadMoreEvent();
}

final class WorkersListSearchChangedEvent extends WorkersListEvent {
  const WorkersListSearchChangedEvent(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// Replaces a worker in the list by id. Dispatched after an edit succeeds or
/// after `WorkerActionCubit` reports a status change so the list reflects the
/// new data without an extra API round-trip.
final class WorkerReplacedInListEvent extends WorkersListEvent {
  const WorkerReplacedInListEvent(this.worker);

  final WorkerEntity worker;

  @override
  List<Object?> get props => [worker];
}

/// Removes a worker from the list by id. Dispatched by the page after
/// `WorkerActionCubit` reports a successful delete.
final class WorkerRemovedFromListEvent extends WorkersListEvent {
  const WorkerRemovedFromListEvent(this.workerId);

  final String workerId;

  @override
  List<Object?> get props => [workerId];
}
