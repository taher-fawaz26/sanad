part of 'roles_list_bloc.dart';

sealed class RolesListEvent extends Equatable {
  const RolesListEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the first page (initial load / first-page-error retry).
class LoadRolesEvent extends RolesListEvent {
  const LoadRolesEvent();
}

/// Pull-to-refresh: reloads page 1, preserving the active search query.
class RefreshRolesEvent extends RolesListEvent {
  const RefreshRolesEvent();
}

/// Loads the next page and appends it.
class LoadMoreRolesEvent extends RolesListEvent {
  const LoadMoreRolesEvent();
}

/// Server-side search: debounced, resets to page 1.
class SearchRolesChangedEvent extends RolesListEvent {
  const SearchRolesChangedEvent(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
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
