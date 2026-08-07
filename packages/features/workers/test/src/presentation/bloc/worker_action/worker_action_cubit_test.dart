import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/entities/worker_status.dart';
import 'package:workers/src/domain/repositories/worker_repository.dart';
import 'package:workers/src/domain/usecases/delete_worker_usecase.dart';
import 'package:workers/src/domain/usecases/update_worker_status_usecase.dart';
import 'package:workers/src/presentation/bloc/worker_action/worker_action_cubit.dart';

class _MockRepo extends Mock implements WorkerRepository {}

const _worker = WorkerEntity(
  id: 'w1',
  fullName: 'Ada',
  role: 'worker',
  initials: 'AL',
  status: WorkerStatus.active,
);

void main() {
  late _MockRepo repo;
  late WorkerActionCubit cubit;

  setUp(() {
    repo = _MockRepo();
    cubit = WorkerActionCubit(
      deleteWorkerUseCase: DeleteWorkerUseCase(repo),
      updateWorkerStatusUseCase: UpdateWorkerStatusUseCase(repo),
    );
  });

  tearDown(() => cubit.close());

  test('delete: emits Started then Succeeded on success', () async {
    when(() => repo.deleteWorker('w1')).thenAnswer((_) => TaskEither.of(unit));
    final effects = <WorkerActionEffect>[];
    final sub = cubit.effects.listen(effects.add);

    await cubit.delete('w1');
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(effects, [
      const WorkerActionStarted(WorkerActionType.delete),
      const WorkerActionSucceeded(
        type: WorkerActionType.delete,
        workerId: 'w1',
      ),
    ]);
    expect(cubit.state.isBusy, isFalse);
  });

  test('delete: emits Started then Failed on failure', () async {
    when(() => repo.deleteWorker('w1')).thenAnswer(
      (_) => TaskEither.left(const NetworkFailure(message: 'boom')),
    );
    final effects = <WorkerActionEffect>[];
    final sub = cubit.effects.listen(effects.add);

    await cubit.delete('w1');
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(effects.length, 2);
    expect(effects[0], const WorkerActionStarted(WorkerActionType.delete));
    expect(effects[1], isA<WorkerActionFailed>());
  });

  test(
    'changeStatus: emits Succeeded with updated worker on success',
    () async {
      when(
        () => repo.updateWorkerStatus('w1', WorkerStatus.inactive),
      ).thenAnswer((_) => TaskEither.of(_worker));

      final effects = <WorkerActionEffect>[];
      final sub = cubit.effects.listen(effects.add);

      await cubit.changeStatus(
        workerId: 'w1',
        status: WorkerStatus.inactive,
      );
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(effects.length, 2);
      expect(effects[0], const WorkerActionStarted(WorkerActionType.suspend));
      expect(effects[1], isA<WorkerActionSucceeded>());
      final succeeded = effects[1] as WorkerActionSucceeded;
      expect(succeeded.type, WorkerActionType.suspend);
      expect(succeeded.workerId, 'w1');
      expect(succeeded.updatedWorker, isNotNull);
    },
  );

  test('ignores a second call while an action is in flight', () async {
    final gate = Completer<Either<Failure, Unit>>();
    when(
      () => repo.deleteWorker('w1'),
    ).thenAnswer((_) => TaskEither(() => gate.future));

    final effects = <WorkerActionEffect>[];
    final sub = cubit.effects.listen(effects.add);

    final first = cubit.delete('w1');
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.isBusy, isTrue);

    // Second call while busy — should no-op.
    await cubit.delete('w1');
    // Only the Started from the first call should be present so far.
    expect(effects, [const WorkerActionStarted(WorkerActionType.delete)]);

    gate.complete(right(unit));
    await first;
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(cubit.state.isBusy, isFalse);
    expect(effects.length, 2);
  });
}
