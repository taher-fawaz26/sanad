import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:provider_rbac/src/domain/usecases/get_roles_usecase.dart';

part 'roles_list_event.dart';
part 'roles_list_state.dart';

class RolesListBloc extends Bloc<RolesListEvent, RolesListState> {
  RolesListBloc({required GetRolesUseCase getRolesUseCase})
    : _getRolesUseCase = getRolesUseCase,
      super(const RolesListState()) {
    on<LoadRolesEvent>(_onLoad);
    on<RefreshRolesEvent>(_onLoad);
    on<RoleRemovedFromListEvent>(_onRoleRemoved);
    on<RoleUpsertedInListEvent>(_onRoleUpserted);
  }

  final GetRolesUseCase _getRolesUseCase;

  Future<void> _onLoad(
    RolesListEvent event,
    Emitter<RolesListState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading));

    final result = await _getRolesUseCase.call(const NoParams()).run();

    result.match(
      (failure) => emit(
        state.copyWith(status: RequestStatus.failure, failure: failure),
      ),
      (roles) => emit(
        state.copyWith(status: RequestStatus.success, roles: roles),
      ),
    );
  }

  void _onRoleRemoved(
    RoleRemovedFromListEvent event,
    Emitter<RolesListState> emit,
  ) {
    emit(
      state.copyWith(
        roles: state.roles.where((r) => r.id != event.roleId).toList(),
      ),
    );
  }

  void _onRoleUpserted(
    RoleUpsertedInListEvent event,
    Emitter<RolesListState> emit,
  ) {
    final exists = state.roles.any((r) => r.id == event.role.id);
    final updated = exists
        ? state.roles
              .map((r) => r.id == event.role.id ? event.role : r)
              .toList()
        : [...state.roles, event.role];
    emit(state.copyWith(roles: updated));
  }
}
