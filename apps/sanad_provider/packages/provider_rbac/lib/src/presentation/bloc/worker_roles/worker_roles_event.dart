part of 'worker_roles_bloc.dart';

sealed class WorkerRolesEvent extends Equatable {
  const WorkerRolesEvent();

  @override
  List<Object?> get props => [];
}

class LoadWorkerRolesEvent extends WorkerRolesEvent {
  const LoadWorkerRolesEvent(this.workerId);

  final String workerId;

  @override
  List<Object?> get props => [workerId];
}

/// Also loads the full role catalog so the assign sheet can present it —
/// only needed when the "manage roles" sheet is opened.
class LoadAssignableRolesEvent extends WorkerRolesEvent {
  const LoadAssignableRolesEvent();
}

class AssignRolesRequestedEvent extends WorkerRolesEvent {
  const AssignRolesRequestedEvent({
    required this.workerId,
    required this.roleIds,
  });

  final String workerId;
  final List<String> roleIds;

  @override
  List<Object?> get props => [workerId, roleIds];
}
