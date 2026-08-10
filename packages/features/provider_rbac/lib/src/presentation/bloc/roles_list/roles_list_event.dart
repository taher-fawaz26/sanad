part of 'roles_list_bloc.dart';

sealed class RolesListEvent extends Equatable {
  const RolesListEvent();

  @override
  List<Object?> get props => [];
}

class LoadRolesEvent extends RolesListEvent {
  const LoadRolesEvent();
}

class RefreshRolesEvent extends RolesListEvent {
  const RefreshRolesEvent();
}

/// Folded-update event: patches the list locally after a role was deleted
/// elsewhere (via [RoleActionBloc]), avoiding a refetch.
class RoleRemovedFromListEvent extends RolesListEvent {
  const RoleRemovedFromListEvent(this.roleId);

  final String roleId;

  @override
  List<Object?> get props => [roleId];
}

/// Folded-update event: patches the list locally after a role was
/// created/updated elsewhere (via [RoleFormBloc]).
class RoleUpsertedInListEvent extends RolesListEvent {
  const RoleUpsertedInListEvent(this.role);

  final RoleEntity role;

  @override
  List<Object?> get props => [role];
}
