import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider_rbac/src/domain/repositories/roles_repository.dart';
import 'package:provider_rbac/src/domain/usecases/delete_role_usecase.dart';
import 'package:provider_rbac/src/presentation/bloc/role_action/role_action_bloc.dart';

class _MockRolesRepository extends Mock implements RolesRepository {}

void main() {
  late _MockRolesRepository repository;

  setUp(() => repository = _MockRolesRepository());

  blocTest<RoleActionBloc, RoleActionState>(
    'DeleteRoleRequestedEvent emits [inProgress, success]',
    build: () {
      when(() => repository.deleteRole('role_1')).thenAnswer(
        (_) => TaskEither.of(unit),
      );
      return RoleActionBloc(
        deleteRoleUseCase: DeleteRoleUseCase(repository),
      );
    },
    act: (bloc) => bloc.add(const DeleteRoleRequestedEvent('role_1')),
    expect: () => [
      const RoleActionState(
        status: RoleActionStatus.inProgress,
        roleId: 'role_1',
      ),
      const RoleActionState(
        status: RoleActionStatus.success,
        roleId: 'role_1',
      ),
    ],
  );

  blocTest<RoleActionBloc, RoleActionState>(
    'DeleteRoleRequestedEvent emits [inProgress, failure] on error',
    build: () {
      when(() => repository.deleteRole('role_1')).thenAnswer(
        (_) => TaskEither.left(const ConflictFailure(message: 'in use')),
      );
      return RoleActionBloc(
        deleteRoleUseCase: DeleteRoleUseCase(repository),
      );
    },
    act: (bloc) => bloc.add(const DeleteRoleRequestedEvent('role_1')),
    expect: () => [
      const RoleActionState(
        status: RoleActionStatus.inProgress,
        roleId: 'role_1',
      ),
      const RoleActionState(
        status: RoleActionStatus.failure,
        roleId: 'role_1',
        failure: ConflictFailure(message: 'in use'),
      ),
    ],
  );
}
