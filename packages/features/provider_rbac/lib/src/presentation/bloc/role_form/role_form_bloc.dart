import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider_rbac/src/domain/entities/permission_entity.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:provider_rbac/src/domain/usecases/create_role_usecase.dart';
import 'package:provider_rbac/src/domain/usecases/get_permissions_usecase.dart';
import 'package:provider_rbac/src/domain/usecases/update_role_usecase.dart';

part 'role_form_event.dart';
part 'role_form_state.dart';

/// Drives both the create-role and edit-role forms: loads the live
/// permission catalog for the multi-select, tracks the selected permission
/// ids, and submits either a create or an update depending on which event
/// the page fires.
class RoleFormBloc extends Bloc<RoleFormEvent, RoleFormState> {
  RoleFormBloc({
    required GetPermissionsUseCase getPermissionsUseCase,
    required CreateRoleUseCase createRoleUseCase,
    required UpdateRoleUseCase updateRoleUseCase,
  }) : _getPermissionsUseCase = getPermissionsUseCase,
       _createRoleUseCase = createRoleUseCase,
       _updateRoleUseCase = updateRoleUseCase,
       super(const RoleFormState()) {
    on<LoadPermissionCatalogEvent>(_onLoadCatalog);
    on<TogglePermissionEvent>(_onTogglePermission);
    on<SubmitCreateRoleEvent>(_onSubmitCreate);
    on<SubmitUpdateRoleEvent>(_onSubmitUpdate);
  }

  final GetPermissionsUseCase _getPermissionsUseCase;
  final CreateRoleUseCase _createRoleUseCase;
  final UpdateRoleUseCase _updateRoleUseCase;

  Future<void> _onLoadCatalog(
    LoadPermissionCatalogEvent event,
    Emitter<RoleFormState> emit,
  ) async {
    emit(state.copyWith(catalogStatus: RequestStatus.loading));

    final result = await _getPermissionsUseCase.call(const NoParams()).run();

    result.match(
      (failure) => emit(
        state.copyWith(catalogStatus: RequestStatus.failure, failure: failure),
      ),
      (permissions) => emit(
        state.copyWith(
          catalogStatus: RequestStatus.success,
          permissions: permissions,
          selectedPermissionIds: {
            ...event.initialRole?.permissions.map((p) => p.id) ?? const [],
          },
        ),
      ),
    );
  }

  void _onTogglePermission(
    TogglePermissionEvent event,
    Emitter<RoleFormState> emit,
  ) {
    final updated = {...state.selectedPermissionIds};
    if (!updated.remove(event.permissionId)) {
      updated.add(event.permissionId);
    }
    emit(state.copyWith(selectedPermissionIds: updated));
  }

  Future<void> _onSubmitCreate(
    SubmitCreateRoleEvent event,
    Emitter<RoleFormState> emit,
  ) async {
    emit(state.copyWith(submitStatus: RoleFormSubmitStatus.submitting));

    final result = await _createRoleUseCase
        .call(
          CreateRoleParams(
            name: event.name,
            displayName: event.displayName,
            displayNameAr: event.displayNameAr,
            description: event.description,
            descriptionAr: event.descriptionAr,
            permissionIds: state.selectedPermissionIds.toList(),
          ),
        )
        .run();

    result.match(
      (failure) => emit(
        state.copyWith(
          submitStatus: RoleFormSubmitStatus.failure,
          failure: failure,
        ),
      ),
      (role) => emit(
        state.copyWith(
          submitStatus: RoleFormSubmitStatus.success,
          savedRole: role,
        ),
      ),
    );
  }

  Future<void> _onSubmitUpdate(
    SubmitUpdateRoleEvent event,
    Emitter<RoleFormState> emit,
  ) async {
    emit(state.copyWith(submitStatus: RoleFormSubmitStatus.submitting));

    final result = await _updateRoleUseCase
        .call(
          UpdateRoleParams(
            id: event.roleId,
            name: event.name,
            displayName: event.displayName,
            displayNameAr: event.displayNameAr,
            description: event.description,
            descriptionAr: event.descriptionAr,
            permissionIds: state.selectedPermissionIds.toList(),
          ),
        )
        .run();

    result.match(
      (failure) => emit(
        state.copyWith(
          submitStatus: RoleFormSubmitStatus.failure,
          failure: failure,
        ),
      ),
      (role) => emit(
        state.copyWith(
          submitStatus: RoleFormSubmitStatus.success,
          savedRole: role,
        ),
      ),
    );
  }
}
