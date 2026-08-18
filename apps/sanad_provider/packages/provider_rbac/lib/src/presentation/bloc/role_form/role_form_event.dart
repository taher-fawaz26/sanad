part of 'role_form_bloc.dart';

sealed class RoleFormEvent extends Equatable {
  const RoleFormEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the live permission catalog. [initialRole] pre-selects its
/// permissions (edit mode) — null for create mode.
class LoadPermissionCatalogEvent extends RoleFormEvent {
  const LoadPermissionCatalogEvent({this.initialRole});

  final RoleEntity? initialRole;

  @override
  List<Object?> get props => [initialRole];
}

class TogglePermissionEvent extends RoleFormEvent {
  const TogglePermissionEvent(this.permissionId);

  final String permissionId;

  @override
  List<Object?> get props => [permissionId];
}

class SubmitCreateRoleEvent extends RoleFormEvent {
  const SubmitCreateRoleEvent({
    required this.name,
    required this.displayName,
    this.description,
  });

  final String name;
  final String displayName;
  final String? description;

  @override
  List<Object?> get props => [name, displayName, description];
}

class SubmitUpdateRoleEvent extends RoleFormEvent {
  const SubmitUpdateRoleEvent({
    required this.roleId,
    required this.name,
    required this.displayName,
    this.description,
  });

  final String roleId;
  final String name;
  final String displayName;
  final String? description;

  @override
  List<Object?> get props => [roleId, name, displayName, description];
}
