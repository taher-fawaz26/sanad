import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:provider_rbac/src/domain/entities/role_persona_type.dart';
import 'package:provider_rbac/src/domain/repositories/roles_repository.dart';
import 'package:provider_rbac/src/domain/usecases/assign_worker_roles_usecase.dart';
import 'package:provider_rbac/src/domain/usecases/get_roles_usecase.dart';
import 'package:provider_rbac/src/domain/usecases/get_worker_roles_usecase.dart';
import 'package:provider_rbac/src/domain/usecases/remove_worker_role_usecase.dart';
import 'package:provider_rbac/src/presentation/bloc/worker_roles/worker_roles_bloc.dart';

class _MockRolesRepository extends Mock implements RolesRepository {}

RoleEntity _role(String id) => RoleEntity(
  id: id,
  name: 'role-$id',
  displayName: 'Role $id',
  userType: RolePersonaType.worker,
  isSystem: false,
  permissions: const [],
);

WorkerRolesBloc _buildBloc(RolesRepository repository) => WorkerRolesBloc(
  getWorkerRolesUseCase: GetWorkerRolesUseCase(repository),
  getRolesUseCase: GetRolesUseCase(repository),
  assignWorkerRolesUseCase: AssignWorkerRolesUseCase(repository),
  removeWorkerRoleUseCase: RemoveWorkerRoleUseCase(repository),
);

void main() {
  late _MockRolesRepository repository;

  setUp(() => repository = _MockRolesRepository());

  blocTest<WorkerRolesBloc, WorkerRolesState>(
    'LoadWorkerRolesEvent emits [loading, success] with the worker roles',
    build: () {
      when(() => repository.getWorkerRoles('w1')).thenAnswer(
        (_) => TaskEither.of([_role('a')]),
      );
      return _buildBloc(repository);
    },
    act: (bloc) => bloc.add(const LoadWorkerRolesEvent('w1')),
    expect: () => [
      const WorkerRolesState(status: RequestStatus.loading),
      WorkerRolesState(status: RequestStatus.success, roles: [_role('a')]),
    ],
  );

  blocTest<WorkerRolesBloc, WorkerRolesState>(
    'AssignRolesRequestedEvent replaces roles and marks mutation success',
    build: () {
      when(
        () => repository.assignWorkerRoles(
          workerId: 'w1',
          roleIds: ['b'],
        ),
      ).thenAnswer((_) => TaskEither.of([_role('b')]));
      return _buildBloc(repository);
    },
    seed: () =>
        WorkerRolesState(status: RequestStatus.success, roles: [_role('a')]),
    act: (bloc) => bloc.add(
      const AssignRolesRequestedEvent(workerId: 'w1', roleIds: ['b']),
    ),
    expect: () => [
      WorkerRolesState(
        status: RequestStatus.success,
        roles: [_role('a')],
        mutationStatus: RequestStatus.loading,
      ),
      WorkerRolesState(
        status: RequestStatus.success,
        roles: [_role('b')],
        mutationStatus: RequestStatus.success,
      ),
    ],
  );

  blocTest<WorkerRolesBloc, WorkerRolesState>(
    'AssignRolesRequestedEvent with an empty list clears all roles',
    build: () {
      when(
        () => repository.assignWorkerRoles(
          workerId: 'w1',
          roleIds: const [],
        ),
      ).thenAnswer((_) => TaskEither.of(const []));
      return _buildBloc(repository);
    },
    seed: () =>
        WorkerRolesState(status: RequestStatus.success, roles: [_role('a')]),
    act: (bloc) => bloc.add(
      const AssignRolesRequestedEvent(workerId: 'w1', roleIds: []),
    ),
    expect: () => [
      WorkerRolesState(
        status: RequestStatus.success,
        roles: [_role('a')],
        mutationStatus: RequestStatus.loading,
      ),
      const WorkerRolesState(
        status: RequestStatus.success,
        roles: [],
        mutationStatus: RequestStatus.success,
      ),
    ],
  );

  blocTest<WorkerRolesBloc, WorkerRolesState>(
    'RemoveRoleRequestedEvent removes the role and marks mutation success',
    build: () {
      when(
        () => repository.removeWorkerRole(
          workerId: 'w1',
          roleId: 'a',
        ),
      ).thenAnswer((_) => TaskEither.of(unit));
      return _buildBloc(repository);
    },
    seed: () => WorkerRolesState(
      status: RequestStatus.success,
      roles: [_role('a'), _role('b')],
    ),
    act: (bloc) => bloc.add(
      const RemoveRoleRequestedEvent(workerId: 'w1', roleId: 'a'),
    ),
    expect: () => [
      WorkerRolesState(
        status: RequestStatus.success,
        roles: [_role('a'), _role('b')],
        mutationStatus: RequestStatus.loading,
      ),
      WorkerRolesState(
        status: RequestStatus.success,
        roles: [_role('b')],
        mutationStatus: RequestStatus.success,
      ),
    ],
  );
}
