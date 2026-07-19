part of 'workers_bloc.dart';

sealed class WorkersEvent extends Equatable {
  const WorkersEvent();

  @override
  List<Object?> get props => [];
}

final class WorkersFetchEvent extends WorkersEvent {
  const WorkersFetchEvent();
}

final class WorkersRefreshEvent extends WorkersEvent {
  const WorkersRefreshEvent();
}

final class WorkersSearchChangedEvent extends WorkersEvent {
  const WorkersSearchChangedEvent(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class WorkerDeletedEvent extends WorkersEvent {
  const WorkerDeletedEvent(this.workerId);

  final String workerId;

  @override
  List<Object?> get props => [workerId];
}

final class WorkerStatusChangedEvent extends WorkersEvent {
  const WorkerStatusChangedEvent({
    required this.workerId,
    required this.status,
  });

  final String workerId;
  final WorkerStatus status;

  @override
  List<Object?> get props => [workerId, status];
}

final class WorkerActionFailureClearedEvent extends WorkersEvent {
  const WorkerActionFailureClearedEvent();
}
