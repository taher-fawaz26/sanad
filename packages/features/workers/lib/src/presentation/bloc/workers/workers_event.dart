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

final class WorkersLoadMoreEvent extends WorkersEvent {
  const WorkersLoadMoreEvent();
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

final class WorkersTabChangedEvent extends WorkersEvent {
  const WorkersTabChangedEvent(this.tabIndex);

  final int tabIndex;

  @override
  List<Object?> get props => [tabIndex];
}

final class InvitationsFetchEvent extends WorkersEvent {
  const InvitationsFetchEvent();
}

final class InvitationsRefreshEvent extends WorkersEvent {
  const InvitationsRefreshEvent();
}

final class InvitationsLoadMoreEvent extends WorkersEvent {
  const InvitationsLoadMoreEvent();
}

final class InvitationResendEvent extends WorkersEvent {
  const InvitationResendEvent(this.invitationId);

  final String invitationId;

  @override
  List<Object?> get props => [invitationId];
}

final class InvitationCancelledEvent extends WorkersEvent {
  const InvitationCancelledEvent(this.invitationId);

  final String invitationId;

  @override
  List<Object?> get props => [invitationId];
}
