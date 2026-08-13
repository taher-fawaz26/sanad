import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:workers/src/domain/repositories/worker_repository.dart';
import 'package:workers/src/domain/usecases/cancel_invitation_usecase.dart';
import 'package:workers/src/domain/usecases/delete_invitation_usecase.dart';
import 'package:workers/src/domain/usecases/resend_invitation_usecase.dart';
import 'package:workers/src/presentation/bloc/invitation_action/invitation_action_cubit.dart';

class _MockRepo extends Mock implements WorkerRepository {}

void main() {
  late _MockRepo repo;
  late InvitationActionCubit cubit;

  setUp(() {
    repo = _MockRepo();
    cubit = InvitationActionCubit(
      resendInvitationUseCase: ResendInvitationUseCase(repo),
      cancelInvitationUseCase: CancelInvitationUseCase(repo),
      deleteInvitationUseCase: DeleteInvitationUseCase(repo),
    );
  });

  tearDown(() => cubit.close());

  test('resend: emits Started then Succeeded on success', () async {
    when(
      () => repo.resendInvitation('i1'),
    ).thenAnswer((_) => TaskEither.of(unit));
    final effects = <InvitationActionEffect>[];
    final sub = cubit.effects.listen(effects.add);

    await cubit.resend('i1');
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(effects, [
      const InvitationActionStarted(InvitationActionType.resend),
      const InvitationActionSucceeded(
        type: InvitationActionType.resend,
        invitationId: 'i1',
      ),
    ]);
    expect(cubit.state.isBusy, isFalse);
  });

  test('cancel: emits Started then Failed on failure', () async {
    when(() => repo.cancelInvitation('i1')).thenAnswer(
      (_) => TaskEither.left(const NetworkFailure(message: 'boom')),
    );
    final effects = <InvitationActionEffect>[];
    final sub = cubit.effects.listen(effects.add);

    await cubit.cancel('i1');
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(effects.length, 2);
    expect(
      effects[0],
      const InvitationActionStarted(InvitationActionType.cancel),
    );
    expect(effects[1], isA<InvitationActionFailed>());
  });

  test('delete: emits Started then Succeeded on success', () async {
    when(
      () => repo.deleteInvitation('i1'),
    ).thenAnswer((_) => TaskEither.of(unit));
    final effects = <InvitationActionEffect>[];
    final sub = cubit.effects.listen(effects.add);

    await cubit.delete('i1');
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(effects.length, 2);
    expect(
      effects[0],
      const InvitationActionStarted(InvitationActionType.delete),
    );
    expect(effects[1], isA<InvitationActionSucceeded>());
  });

  test('ignores a second call while an action is in flight', () async {
    final gate = Completer<Either<Failure, Unit>>();
    when(
      () => repo.resendInvitation('i1'),
    ).thenAnswer((_) => TaskEither(() => gate.future));

    final effects = <InvitationActionEffect>[];
    final sub = cubit.effects.listen(effects.add);

    final first = cubit.resend('i1');
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.isBusy, isTrue);

    // Second call while busy — should no-op (no duplicate API call).
    await cubit.resend('i1');
    expect(effects, [
      const InvitationActionStarted(InvitationActionType.resend),
    ]);
    verify(() => repo.resendInvitation('i1')).called(1);

    gate.complete(right(unit));
    await first;
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(cubit.state.isBusy, isFalse);
    expect(effects.length, 2);
  });
}
