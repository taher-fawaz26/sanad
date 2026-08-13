import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider_rbac/src/domain/usecases/delete_role_usecase.dart';

part 'role_action_event.dart';
part 'role_action_state.dart';

/// Single-role mutation state (currently: delete). Kept separate from
/// [RolesListBloc] so the list itself stays a pure read model; the page
/// listens here and folds the result back into the list via
/// `RoleRemovedFromListEvent`.
class RoleActionBloc extends Bloc<RoleActionEvent, RoleActionState> {
  RoleActionBloc({required DeleteRoleUseCase deleteRoleUseCase})
    : _deleteRoleUseCase = deleteRoleUseCase,
      super(const RoleActionState()) {
    // Drop duplicate delete taps while one is in flight (double-tap guard).
    on<DeleteRoleRequestedEvent>(_onDeleteRequested, transformer: droppable());
  }

  final DeleteRoleUseCase _deleteRoleUseCase;

  Future<void> _onDeleteRequested(
    DeleteRoleRequestedEvent event,
    Emitter<RoleActionState> emit,
  ) async {
    emit(
      state.copyWith(
        status: RoleActionStatus.inProgress,
        roleId: event.roleId,
      ),
    );

    final result = await _deleteRoleUseCase
        .call(DeleteRoleParams(event.roleId))
        .run();

    result.match(
      (failure) => emit(
        state.copyWith(status: RoleActionStatus.failure, failure: failure),
      ),
      (_) => emit(state.copyWith(status: RoleActionStatus.success)),
    );
  }
}
