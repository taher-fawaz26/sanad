import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider_rbac/src/domain/entities/permission_entity.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:provider_rbac/src/domain/entities/role_persona_type.dart';
import 'package:provider_rbac/src/domain/repositories/permissions_repository.dart';
import 'package:provider_rbac/src/domain/repositories/roles_repository.dart';
import 'package:provider_rbac/src/domain/usecases/create_role_usecase.dart';
import 'package:provider_rbac/src/domain/usecases/get_permissions_usecase.dart';
import 'package:provider_rbac/src/domain/usecases/update_role_usecase.dart';
import 'package:provider_rbac/src/presentation/bloc/role_form/role_form_bloc.dart';

class _MockPermissionsRepository extends Mock
    implements PermissionsRepository {}

class _MockRolesRepository extends Mock implements RolesRepository {}

const _perm1 = PermissionEntity(
  id: 'perm_1',
  action: 'branch:create',
  displayName: 'Create branch',
  resource: 'branch',
);
const _perm2 = PermissionEntity(
  id: 'perm_2',
  action: 'branch:delete',
  displayName: 'Delete branch',
  resource: 'branch',
);

RoleFormBloc _buildBloc({
  required PermissionsRepository permissionsRepository,
  required RolesRepository rolesRepository,
}) => RoleFormBloc(
  getPermissionsUseCase: GetPermissionsUseCase(permissionsRepository),
  createRoleUseCase: CreateRoleUseCase(rolesRepository),
  updateRoleUseCase: UpdateRoleUseCase(rolesRepository),
);

void main() {
  late _MockPermissionsRepository permissionsRepository;
  late _MockRolesRepository rolesRepository;

  setUp(() {
    permissionsRepository = _MockPermissionsRepository();
    rolesRepository = _MockRolesRepository();
  });

  blocTest<RoleFormBloc, RoleFormState>(
    'LoadPermissionCatalogEvent pre-selects the initial role permissions',
    build: () {
      when(permissionsRepository.getPermissions).thenAnswer(
        (_) => TaskEither.of([_perm1, _perm2]),
      );
      return _buildBloc(
        permissionsRepository: permissionsRepository,
        rolesRepository: rolesRepository,
      );
    },
    act: (bloc) => bloc.add(
      LoadPermissionCatalogEvent(
        initialRole: RoleEntity(
          id: 'role_1',
          name: 'x',
          displayName: 'X',
          userType: RolePersonaType.companyProvider,
          isSystem: false,
          permissions: const [_perm1],
        ),
      ),
    ),
    expect: () => [
      const RoleFormState(catalogStatus: RequestStatus.loading),
      const RoleFormState(
        catalogStatus: RequestStatus.success,
        permissions: [_perm1, _perm2],
        selectedPermissionIds: {'perm_1'},
      ),
    ],
  );

  blocTest<RoleFormBloc, RoleFormState>(
    'TogglePermissionEvent adds then removes a permission id',
    build: () => _buildBloc(
      permissionsRepository: permissionsRepository,
      rolesRepository: rolesRepository,
    ),
    act: (bloc) => bloc
      ..add(const TogglePermissionEvent('perm_1'))
      ..add(const TogglePermissionEvent('perm_1')),
    expect: () => [
      const RoleFormState(selectedPermissionIds: {'perm_1'}),
      const RoleFormState(selectedPermissionIds: {}),
    ],
  );

  blocTest<RoleFormBloc, RoleFormState>(
    'SubmitCreateRoleEvent sends the currently selected permissions',
    build: () {
      when(
        () => rolesRepository.createRole(
          name: any(named: 'name'),
          displayName: any(named: 'displayName'),
          description: any(named: 'description'),
          permissionIds: any(named: 'permissionIds'),
        ),
      ).thenAnswer(
        (_) => TaskEither.of(
          const RoleEntity(
            id: 'role_1',
            name: 'x',
            displayName: 'X',
            userType: RolePersonaType.companyProvider,
            isSystem: false,
            permissions: [_perm1],
          ),
        ),
      );
      return _buildBloc(
        permissionsRepository: permissionsRepository,
        rolesRepository: rolesRepository,
      );
    },
    seed: () => const RoleFormState(selectedPermissionIds: {'perm_1'}),
    act: (bloc) => bloc.add(
      const SubmitCreateRoleEvent(name: 'x', displayName: 'X'),
    ),
    expect: () => [
      const RoleFormState(
        selectedPermissionIds: {'perm_1'},
        submitStatus: RoleFormSubmitStatus.submitting,
      ),
      const RoleFormState(
        selectedPermissionIds: {'perm_1'},
        submitStatus: RoleFormSubmitStatus.success,
        savedRole: RoleEntity(
          id: 'role_1',
          name: 'x',
          displayName: 'X',
          userType: RolePersonaType.companyProvider,
          isSystem: false,
          permissions: [_perm1],
        ),
      ),
    ],
    verify: (_) {
      verify(
        () => rolesRepository.createRole(
          name: 'x',
          displayName: 'X',
          description: null,
          permissionIds: ['perm_1'],
        ),
      ).called(1);
    },
  );

  test(
    'droppable(): a second SubmitCreateRoleEvent while one is in flight '
    'does not fire a duplicate API call',
    () async {
      final gate = Completer<RoleEntity>();
      when(
        () => rolesRepository.createRole(
          name: any(named: 'name'),
          displayName: any(named: 'displayName'),
          description: any(named: 'description'),
          permissionIds: any(named: 'permissionIds'),
        ),
      ).thenAnswer((_) => TaskEither(() => gate.future.then(Right.new)));

      final bloc = _buildBloc(
        permissionsRepository: permissionsRepository,
        rolesRepository: rolesRepository,
      );
      addTearDown(bloc.close);

      bloc
        ..add(const SubmitCreateRoleEvent(name: 'x', displayName: 'X'))
        ..add(const SubmitCreateRoleEvent(name: 'x', displayName: 'X'));
      await Future<void>.delayed(Duration.zero);

      gate.complete(
        const RoleEntity(
          id: 'role_1',
          name: 'x',
          displayName: 'X',
          userType: RolePersonaType.companyProvider,
          isSystem: false,
          permissions: [_perm1],
        ),
      );
      await Future<void>.delayed(Duration.zero);

      verify(
        () => rolesRepository.createRole(
          name: 'x',
          displayName: 'X',
          description: null,
          permissionIds: any(named: 'permissionIds'),
        ),
      ).called(1);
    },
  );
}
