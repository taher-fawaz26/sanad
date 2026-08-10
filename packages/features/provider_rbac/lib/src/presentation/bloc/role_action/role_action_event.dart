part of 'role_action_bloc.dart';

sealed class RoleActionEvent extends Equatable {
  const RoleActionEvent();

  @override
  List<Object?> get props => [];
}

class DeleteRoleRequestedEvent extends RoleActionEvent {
  const DeleteRoleRequestedEvent(this.roleId);

  final String roleId;

  @override
  List<Object?> get props => [roleId];
}
