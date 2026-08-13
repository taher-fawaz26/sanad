import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
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

// ── Root-cause note ──────────────────────────────────────────────────────
// This file intentionally does NOT bootstrap EasyLocalization
// (`EasyLocalization.ensureInitialized()` / `EasyLocalization(...)` widget).
// That call resolves to `EasyLocalizationController.initEasyLocation()`,
// which awaits `SharedPreferences.getInstance()` — a real platform-channel
// call that never completes in this sandboxed test environment, hanging
// every test before `pumpWidget` even runs. This matches the existing
// convention in this repo: no widget test (design_system, shared_ui, or
// elsewhere) bootstraps EasyLocalization — `.tr()` falls back to the raw
// key with a logged warning, which is what these tests assert against.
//
// A separate, unrelated issue: `AppStatusBadge` (used by `WorkerListItem`
// via `AppEntityListItem`) renders its label in a non-`Expanded` Row slot
// with no width constraint above it — `TextOverflow.ellipsis` never
// engages because the Row hands it an unbounded max width. With a real
// short translation ("Active") this never surfaces; with the raw fallback
// key ("workers.status_active") it can overflow. Fixed here purely on the
// test side by matching `ScreenUtilInit.designSize` to the test surface
// size (scale factor ~1), which keeps text/token pixel sizes literal
// instead of inflating them — this alone is sufficient to keep the badge
// well under the available row width. No production code changes needed.

class _MockRepo extends Mock implements WorkerRepository {}

const _activeWorker = WorkerEntity(
  id: 'w1',
  fullName: 'Mohamed',
  role: 'Worker',
  initials: 'M',
  status: WorkerStatus.active,
);

// WorkerStatus.inactive is WorkerEntity's default — omitted, not implicit.
const _suspendedWorker = WorkerEntity(
  id: 'w1',
  fullName: 'Mohamed',
  role: 'Worker',
  initials: 'M',
);

// Real device proportions, but used as BOTH the design size and the test
// surface size so ScreenUtil's scale factor is ~1 — avoids inflating the
// unconstrained AppStatusBadge text (see note above) without touching
// production code.
const _surfaceSize = Size(900, 1200);

Future<void> _pump(
  WidgetTester tester, {
  required WorkerActionCubit actionCubit,
  WorkerEntity worker = _activeWorker,
}) async {
  await tester.binding.setSurfaceSize(_surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: _surfaceSize,
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: MultiBlocProvider(
          providers: [
            BlocProvider<WorkersListBloc>(
              create: (_) => WorkersListBloc(
                getWorkersUseCase: GetWorkersUseCase(_MockRepo()),
              ),
            ),
            BlocProvider<WorkerActionCubit>.value(value: actionCubit),
          ],
          child: Scaffold(body: WorkerListItem(worker: worker)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Opens the swipe pane. `flutter_slidable`'s `AnimationController`-driven
/// open/close reliably settles (confirmed separately in
/// `design_system`'s `app_swipe_actions_test.dart`, which passes with
/// `pumpAndSettle()` in well under a second) — it was never the source of
/// the earlier hang, so `pumpAndSettle()` is safe here. Every test in this
/// file also carries an explicit `timeout: Timeout(20s)`, so if this ever
/// regressed into a genuine non-terminating animation, the test would fail
/// fast at 20s instead of hanging the process indefinitely.
Future<void> _openSwipePane(WidgetTester tester) async {
  await tester.drag(find.text('Mohamed'), const Offset(-300, 0));
  await tester.pumpAndSettle();
}

/// Confirms an action-sheet dialog. See `_openSwipePane` re: pumpAndSettle
/// safety — the sheet's enter/exit transitions
/// (`SheetTransitions.enterDuration` / `exitDuration`) are finite,
/// `AnimationController`-driven, and bounded by each test's 20s timeout.
Future<void> _confirm(WidgetTester tester, String actionLabelKey) async {
  await tester.pumpAndSettle();
  await tester.tap(find.text(actionLabelKey));
  await tester.pumpAndSettle();
}

void main() {
  group('WorkerListItem swipe actions', () {
    late _MockRepo repo;
    late WorkerActionCubit actionCubit;
    late SemanticsHandle semanticsHandle;

    setUp(() {
      repo = _MockRepo();
      actionCubit = WorkerActionCubit(
        deleteWorkerUseCase: DeleteWorkerUseCase(repo),
        updateWorkerStatusUseCase: UpdateWorkerStatusUseCase(repo),
      );
      // find.bySemanticsLabel requires an active semantics tree.
      semanticsHandle = WidgetsBinding.instance.ensureSemantics();
    });

    tearDown(() {
      semanticsHandle.dispose();
      actionCubit.close();
    });

    // Stage 1: WorkerListItem → AppSwipeActions → render only.
    testWidgets(
      'renders worker name and caption',
      (tester) async {
        await _pump(tester, actionCubit: actionCubit);

        expect(find.text('Mohamed'), findsOneWidget);
        expect(find.text('Worker'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    // Stage 2: → swipe → reveal actions.
    testWidgets(
      'swipe reveals Edit / Suspend / Delete actions',
      (tester) async {
        await _pump(tester, actionCubit: actionCubit);

        await _openSwipePane(tester);

        expect(
          find.bySemanticsLabel('workers.action_edit'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('workers.action_suspend'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('workers.action_delete'),
          findsOneWidget,
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'swipe reveals Unsuspend label for a suspended worker',
      (tester) async {
        await _pump(
          tester,
          actionCubit: actionCubit,
          worker: _suspendedWorker,
        );

        await _openSwipePane(tester);

        expect(
          find.bySemanticsLabel('workers.action_unsuspend'),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel('workers.action_suspend'), findsNothing);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    // Stage 3: → action tap → confirmation sheet → BLoC call.
    testWidgets(
      'Suspend swipe action confirms then calls changeStatus',
      (tester) async {
        when(
          () => repo.updateWorkerStatus('w1', WorkerStatus.inactive),
        ).thenAnswer((_) => TaskEither.of(_suspendedWorker));

        await _pump(tester, actionCubit: actionCubit);
        await _openSwipePane(tester);

        await tester.tap(find.bySemanticsLabel('workers.action_suspend'));
        await _confirm(tester, 'workers.suspend_action');

        verify(
          () => repo.updateWorkerStatus('w1', WorkerStatus.inactive),
        ).called(1);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'Delete swipe action confirms then calls delete',
      (tester) async {
        when(
          () => repo.deleteWorker('w1'),
        ).thenAnswer((_) => TaskEither.of(unit));

        await _pump(tester, actionCubit: actionCubit);
        await _openSwipePane(tester);

        await tester.tap(find.bySemanticsLabel('workers.action_delete'));
        await _confirm(tester, 'workers.delete_action');

        verify(() => repo.deleteWorker('w1')).called(1);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'cancelling the confirmation sheet does not call delete',
      (tester) async {
        await _pump(tester, actionCubit: actionCubit);
        await _openSwipePane(tester);

        await tester.tap(find.bySemanticsLabel('workers.action_delete'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('workers.cancel'));
        await tester.pumpAndSettle();

        verifyNever(() => repo.deleteWorker(any()));
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    // The legacy `more_vert` action sheet has been removed — swipe is the
    // only action entry point now.
    testWidgets(
      'exposes no More button / more_vert entry point',
      (tester) async {
        await _pump(tester, actionCubit: actionCubit);

        expect(find.byIcon(Icons.more_vert), findsNothing);
        expect(
          find.bySemanticsLabel('workers.more_actions'),
          findsNothing,
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });
}
