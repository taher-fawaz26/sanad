// ignore_for_file: prefer_const_constructors

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/entities/worker_status.dart';
import 'package:workers/src/domain/repositories/worker_repository.dart';
import 'package:workers/src/domain/usecases/delete_worker_usecase.dart';
import 'package:workers/src/domain/usecases/get_workers_usecase.dart';
import 'package:workers/src/domain/usecases/update_worker_status_usecase.dart';
import 'package:workers/src/presentation/bloc/worker_action/worker_action_cubit.dart';
import 'package:workers/src/presentation/bloc/workers_list/workers_list_bloc.dart';
import 'package:workers/src/presentation/widgets/worker_list_item.dart';

// No EasyLocalization bootstrap — `.tr()` falls back to raw keys.

class _MockWorkerRepository extends Mock implements WorkerRepository {}

const _worker = WorkerEntity(
  id: 'w-1',
  fullName: 'Sam Worker',
  role: 'worker',
  initials: 'SW',
  status: WorkerStatus.active,
);

void main() {
  late _MockWorkerRepository repo;

  setUp(() {
    repo = _MockWorkerRepository();
  });

  Future<void> pumpRow(WidgetTester tester, {required bool isOwner}) async {
    await tester.binding.setSurfaceSize(const Size(1080, 2400));
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final workersList = WorkersListBloc(
      getWorkersUseCase: GetWorkersUseCase(repo),
    );
    final workerAction = WorkerActionCubit(
      deleteWorkerUseCase: DeleteWorkerUseCase(repo),
      updateWorkerStatusUseCase: UpdateWorkerStatusUseCase(repo),
    );
    addTearDown(() {
      workersList.close();
      workerAction.close();
    });

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 800),
        minTextAdapt: true,
        builder: (_, _) => MaterialApp(
          theme: AppTheme.light(),
          home: MultiBlocProvider(
            providers: [
              BlocProvider<WorkersListBloc>.value(value: workersList),
              BlocProvider<WorkerActionCubit>.value(value: workerAction),
            ],
            child: Scaffold(
              body: AppSwipeActionsGroup(
                child: WorkerListItem(worker: _worker, isOwner: isOwner),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('WorkerListItem (RBAC Phase 7M — list-row action gating)', () {
    testWidgets(
      'isOwner: false constructs the row with no swipe actions attached '
      '(all three — Edit / Suspend / Delete — are owner-only mutations '
      'per finding G3)',
      (tester) async {
        await pumpRow(tester, isOwner: false);

        final row = find.byType(WorkerListItem);
        expect(row, findsOneWidget);

        final swipe = tester.widget<AppSwipeActions>(
          find.byType(AppSwipeActions).first,
        );
        expect(
          swipe.actions,
          isEmpty,
          reason:
              "the row must ship with actions: [] for a non-owner so "
              "a swipe gesture reveals nothing (matches the Services row "
              "gate in Phase 7L and the plan's reveal-then-bounce rule)",
        );
      },
    );

    testWidgets(
      'isOwner: true (default) attaches the full three-item swipe list',
      (tester) async {
        await pumpRow(tester, isOwner: true);

        final swipe = tester.widget<AppSwipeActions>(
          find.byType(AppSwipeActions).first,
        );
        expect(swipe.actions.length, 3);
      },
    );
  });
}
