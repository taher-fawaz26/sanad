import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider_rbac/src/data/datasources/provider_rbac_remote_data_source.dart';
import 'package:provider_rbac/src/data/models/assign_worker_roles_dto.dart';
import 'package:provider_rbac/src/data/models/create_role_dto.dart';
import 'package:provider_rbac/src/data/models/role_dto.dart';
import 'package:provider_rbac/src/data/models/update_role_dto.dart';
import 'package:provider_rbac/src/data/repositories/roles_repository_impl.dart';
import 'package:provider_rbac/src/domain/entities/role_persona_type.dart';

class _MockRemoteDataSource extends Mock
    implements ProviderRbacRemoteDataSource {}

void main() {
  late _MockRemoteDataSource remote;
  late RolesRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      const CreateRoleDto(
        name: 'x',
        displayName: 'X',
        permissionIds: [],
      ),
    );
    registerFallbackValue(const UpdateRoleDto());
    registerFallbackValue(const AssignWorkerRolesDto(roleIds: []));
  });

  setUp(() {
    remote = _MockRemoteDataSource();
    repository = RolesRepositoryImpl(remote);
  });

  RoleDto roleDto({String id = 'role_1'}) => RoleDto(
    id: id,
    name: 'branch-manager',
    displayName: 'Branch Manager',
    userType: RolePersonaType.companyProvider,
    isSystem: false,
    permissions: const [],
  );

  test('getRoles maps every DTO to an entity', () async {
    when(remote.getRoles).thenAnswer(
      (_) => TaskEither.of([roleDto(id: 'a'), roleDto(id: 'b')]),
    );

    final result = await repository.getRoles().run();

    expect(result.isRight(), isTrue);
    result.match(
      (_) => fail('expected right'),
      (roles) => expect(roles.map((r) => r.id), ['a', 'b']),
    );
  });

  test('getRoles propagates a Failure from the data source', () async {
    when(remote.getRoles).thenAnswer(
      (_) => TaskEither.left(const ServerFailure(message: 'boom')),
    );

    final result = await repository.getRoles().run();

    expect(result.isLeft(), isTrue);
  });

  test('createRole builds the DTO and maps the response', () async {
    when(() => remote.createRole(any())).thenAnswer(
      (_) => TaskEither.of(roleDto()),
    );

    final result = await repository
        .createRole(
          name: 'branch-manager',
          displayName: 'Branch Manager',
          permissionIds: ['perm_1'],
        )
        .run();

    expect(result.isRight(), isTrue);
    final captured = verify(() => remote.createRole(captureAny())).captured;
    final dto = captured.single as CreateRoleDto;
    expect(dto.name, 'branch-manager');
    expect(dto.permissionIds, ['perm_1']);
  });

  test('deleteRole delegates to the data source', () async {
    when(() => remote.deleteRole('role_1')).thenAnswer(
      (_) => TaskEither.of(unit),
    );

    final result = await repository.deleteRole('role_1').run();

    expect(result.isRight(), isTrue);
    verify(() => remote.deleteRole('role_1')).called(1);
  });

  test(
    'assignWorkerRoles sends a replace request and returns the new roles',
    () async {
      when(() => remote.assignWorkerRoles(any(), any())).thenAnswer(
        (_) => TaskEither.of([roleDto(id: 'a')]),
      );

      final result = await repository
          .assignWorkerRoles(workerId: 'w1', roleIds: ['a'])
          .run();

      expect(result.isRight(), isTrue);
      final captured = verify(
        () => remote.assignWorkerRoles(captureAny(), captureAny()),
      ).captured;
      expect(captured[0], 'w1');
      expect((captured[1] as AssignWorkerRolesDto).roleIds, ['a']);
    },
  );

  test(
    'assignWorkerRoles with an empty list clears all roles',
    () async {
      when(() => remote.assignWorkerRoles(any(), any())).thenAnswer(
        (_) => TaskEither.of(const []),
      );

      final result = await repository
          .assignWorkerRoles(workerId: 'w1', roleIds: const [])
          .run();

      expect(result.isRight(), isTrue);
      result.match(
        (_) => fail('expected right'),
        (roles) => expect(roles, isEmpty),
      );
      final captured = verify(
        () => remote.assignWorkerRoles(captureAny(), captureAny()),
      ).captured;
      expect((captured[1] as AssignWorkerRolesDto).roleIds, isEmpty);
    },
  );

  test('removeWorkerRole delegates to the data source', () async {
    when(() => remote.removeWorkerRole('w1', 'role_1')).thenAnswer(
      (_) => TaskEither.of(unit),
    );

    final result = await repository
        .removeWorkerRole(workerId: 'w1', roleId: 'role_1')
        .run();

    expect(result.isRight(), isTrue);
  });
}
