import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:provider_rbac/src/domain/entities/role_persona_type.dart';
import 'package:provider_rbac/src/domain/repositories/roles_repository.dart';
import 'package:provider_rbac/src/domain/usecases/get_roles_usecase.dart';
import 'package:provider_rbac/src/presentation/bloc/roles_list/roles_list_bloc.dart';

class _MockRolesRepository extends Mock implements RolesRepository {}

RoleEntity _role(String id) => RoleEntity(
  id: id,
  name: 'role-$id',
  displayName: 'Role $id',
  userType: RolePersonaType.companyProvider,
  isSystem: false,
  permissions: const [],
);

void main() {
  late _MockRolesRepository repository;

  setUp(() => repository = _MockRolesRepository());

  blocTest<RolesListBloc, RolesListState>(
    'LoadRolesEvent emits [loading, success] with the fetched roles',
    build: () {
      when(() => repository.getRoles()).thenAnswer(
        (_) => TaskEither.of([_role('a'), _role('b')]),
      );
      return RolesListBloc(getRolesUseCase: GetRolesUseCase(repository));
    },
    act: (bloc) => bloc.add(const LoadRolesEvent()),
    expect: () => [
      const RolesListState(status: RequestStatus.loading),
      RolesListState(
        status: RequestStatus.success,
        roles: [_role('a'), _role('b')],
      ),
    ],
  );

  blocTest<RolesListBloc, RolesListState>(
    'LoadRolesEvent emits [loading, failure] on a repository error',
    build: () {
      when(() => repository.getRoles()).thenAnswer(
        (_) => TaskEither.left(const ServerFailure(message: 'boom')),
      );
      return RolesListBloc(getRolesUseCase: GetRolesUseCase(repository));
    },
    act: (bloc) => bloc.add(const LoadRolesEvent()),
    expect: () => [
      const RolesListState(status: RequestStatus.loading),
      const RolesListState(
        status: RequestStatus.failure,
        failure: ServerFailure(message: 'boom'),
      ),
    ],
  );

  blocTest<RolesListBloc, RolesListState>(
    'RoleRemovedFromListEvent removes the role locally without a refetch',
    build: () => RolesListBloc(getRolesUseCase: GetRolesUseCase(repository)),
    seed: () => RolesListState(
      status: RequestStatus.success,
      roles: [_role('a'), _role('b')],
    ),
    act: (bloc) => bloc.add(const RoleRemovedFromListEvent('a')),
    expect: () => [
      RolesListState(status: RequestStatus.success, roles: [_role('b')]),
    ],
    verify: (_) => verifyNever(() => repository.getRoles()),
  );

  blocTest<RolesListBloc, RolesListState>(
    'RoleUpsertedInListEvent appends a new role and replaces an existing one',
    build: () => RolesListBloc(getRolesUseCase: GetRolesUseCase(repository)),
    seed: () =>
        RolesListState(status: RequestStatus.success, roles: [_role('a')]),
    act: (bloc) => bloc
      ..add(RoleUpsertedInListEvent(_role('b')))
      ..add(
        RoleUpsertedInListEvent(
          RoleEntity(
            id: 'a',
            name: 'renamed',
            displayName: 'Renamed',
            userType: RolePersonaType.companyProvider,
            isSystem: false,
            permissions: const [],
          ),
        ),
      ),
    expect: () => [
      RolesListState(
        status: RequestStatus.success,
        roles: [_role('a'), _role('b')],
      ),
      RolesListState(
        status: RequestStatus.success,
        roles: [
          RoleEntity(
            id: 'a',
            name: 'renamed',
            displayName: 'Renamed',
            userType: RolePersonaType.companyProvider,
            isSystem: false,
            permissions: const [],
          ),
          _role('b'),
        ],
      ),
    ],
  );
}
