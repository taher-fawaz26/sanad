import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:provider_rbac/src/domain/usecases/assign_worker_roles_usecase.dart';
import 'package:provider_rbac/src/domain/usecases/get_roles_usecase.dart';
import 'package:provider_rbac/src/domain/usecases/get_worker_roles_usecase.dart';
import 'package:provider_rbac/src/domain/usecases/remove_worker_role_usecase.dart';
import 'package:provider_rbac/src/domain/usecases/roles_query.dart';

part 'worker_roles_event.dart';
part 'worker_roles_state.dart';

/// Backs the "assigned roles" card on the worker-details screen: loads the
/// worker's current roles, and — on demand — the full role catalog for the
/// "manage roles" sheet, then assigns (replace) or removes a single role.
class WorkerRolesBloc extends Bloc<WorkerRolesEvent, WorkerRolesState> {
  WorkerRolesBloc({
    required GetWorkerRolesUseCase getWorkerRolesUseCase,
    required GetRolesUseCase getRolesUseCase,
    required AssignWorkerRolesUseCase assignWorkerRolesUseCase,
    required RemoveWorkerRoleUseCase removeWorkerRoleUseCase,
  }) : _getWorkerRolesUseCase = getWorkerRolesUseCase,
       _getRolesUseCase = getRolesUseCase,
       _assignWorkerRolesUseCase = assignWorkerRolesUseCase,
       _removeWorkerRoleUseCase = removeWorkerRoleUseCase,
       super(const WorkerRolesState()) {
    on<LoadWorkerRolesEvent>(_onLoadWorkerRoles);
    on<LoadAssignableRolesEvent>(_onLoadCatalog);
    // Drop duplicate submits while one is in flight (double-tap guard).
    on<AssignRolesRequestedEvent>(_onAssignRoles, transformer: droppable());
    on<RemoveRoleRequestedEvent>(_onRemoveRole, transformer: droppable());
  }

  final GetWorkerRolesUseCase _getWorkerRolesUseCase;
  final GetRolesUseCase _getRolesUseCase;
  final AssignWorkerRolesUseCase _assignWorkerRolesUseCase;
  final RemoveWorkerRoleUseCase _removeWorkerRoleUseCase;

  Future<void> _onLoadWorkerRoles(
    LoadWorkerRolesEvent event,
    Emitter<WorkerRolesState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading));

    final result = await _getWorkerRolesUseCase
        .call(GetWorkerRolesParams(event.workerId))
        .run();

    result.match(
      (failure) => emit(
        state.copyWith(status: RequestStatus.failure, failure: failure),
      ),
      (roles) =>
          emit(state.copyWith(status: RequestStatus.success, roles: roles)),
    );
  }

  Future<void> _onLoadCatalog(
    LoadAssignableRolesEvent event,
    Emitter<WorkerRolesState> emit,
  ) async {
    emit(state.copyWith(catalogStatus: RequestStatus.loading));

    // The assignable-roles catalog is a picker, not an infinite list — pull a
    // single large page rather than paginating. Realistic providers have only
    // a handful of roles (system + custom).
    final result = await _getRolesUseCase
        .call(const RolesQuery(limit: 100))
        .run();

    result.match(
      (failure) => emit(
        state.copyWith(catalogStatus: RequestStatus.failure, failure: failure),
      ),
      (page) => emit(
        state.copyWith(
          catalogStatus: RequestStatus.success,
          catalog: page.items,
        ),
      ),
    );
  }

  Future<void> _onAssignRoles(
    AssignRolesRequestedEvent event,
    Emitter<WorkerRolesState> emit,
  ) async {
    emit(state.copyWith(mutationStatus: RequestStatus.loading));

    final result = await _assignWorkerRolesUseCase
        .call(
          AssignWorkerRolesParams(
            workerId: event.workerId,
            roleIds: event.roleIds,
          ),
        )
        .run();

    result.match(
      (failure) => emit(
        state.copyWith(
          mutationStatus: RequestStatus.failure,
          failure: failure,
        ),
      ),
      (roles) => emit(
        state.copyWith(
          mutationStatus: RequestStatus.success,
          status: RequestStatus.success,
          roles: roles,
        ),
      ),
    );
  }

  Future<void> _onRemoveRole(
    RemoveRoleRequestedEvent event,
    Emitter<WorkerRolesState> emit,
  ) async {
    emit(state.copyWith(mutationStatus: RequestStatus.loading));

    final result = await _removeWorkerRoleUseCase
        .call(
          RemoveWorkerRoleParams(
            workerId: event.workerId,
            roleId: event.roleId,
          ),
        )
        .run();

    result.match(
      (failure) => emit(
        state.copyWith(
          mutationStatus: RequestStatus.failure,
          failure: failure,
        ),
      ),
      (_) => emit(
        state.copyWith(
          mutationStatus: RequestStatus.success,
          status: RequestStatus.success,
          roles: state.roles.where((r) => r.id != event.roleId).toList(),
        ),
      ),
    );
  }
}
