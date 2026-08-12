import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
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
import 'package:workers/src/routes/worker_routes.dart';

class _MockRepo extends Mock implements WorkerRepository {}

// Real translated labels (en-US) — matches production so layout-sensitive
// widgets (badges, action sheets) render at their real, short width instead
// of overflowing on raw `workers.foo` translation keys.
const _editLabel = 'Edit Information';
const _suspendLabel = 'Suspend Worker';
const _unsuspendLabel = 'Unsuspend Worker';
const _deleteLabel = 'Delete Worker';
const _confirmSuspend = 'Suspend';
const _confirmDelete = 'Delete';
const _cancelLabel = 'Cancel';

const _activeWorker = WorkerEntity(
  id: 'w1',
  fullName: 'Mohamed',
  role: 'Worker',
  initials: 'M',
);

const _suspendedWorker = WorkerEntity(
  id: 'w1',
  fullName: 'Mohamed',
  role: 'Worker',
  initials: 'M',
  status: WorkerStatus.inactive,
);

Widget _localized(Widget child) {
  return EasyLocalization(
    supportedLocales: const [Locale('en', 'US')],
    path: 'packages/localization/assets/translations',
    startLocale: const Locale('en', 'US'),
    fallbackLocale: const Locale('en', 'US'),
    useOnlyLangCode: false,
    child: child,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required WorkerActionCubit actionCubit,
  WorkerEntity worker = _activeWorker,
}) async {
  await EasyLocalization.ensureInitialized();
  await tester.pumpWidget(
    _localized(
      ScreenUtilInit(
        designSize: const Size(360, 800),
        minTextAdapt: true,
        builder: (context, _) => MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
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
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpWithRouter(
  WidgetTester tester, {
  required WorkerActionCubit actionCubit,
  required WorkersListBloc listBloc,
}) async {
  await EasyLocalization.ensureInitialized();
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => MultiBlocProvider(
          providers: [
            BlocProvider<WorkersListBloc>.value(value: listBloc),
            BlocProvider<WorkerActionCubit>.value(value: actionCubit),
          ],
          child: const Scaffold(body: WorkerListItem(worker: _activeWorker)),
        ),
      ),
      GoRoute(
        path: WorkerRoutes.editWorkerFor(':id'),
        builder: (_, _) => const Scaffold(body: Text('edit-worker-page')),
      ),
    ],
  );

  await tester.pumpWidget(
    _localized(
      ScreenUtilInit(
        designSize: const Size(360, 800),
        minTextAdapt: true,
        builder: (context, _) => MaterialApp.router(
          theme: AppTheme.light(),
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          routerConfig: router,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openSwipePane(WidgetTester tester) async {
  await tester.drag(find.text('Mohamed'), const Offset(-300, 0));
  await tester.pumpAndSettle();
}

Future<void> _confirm(WidgetTester tester, String actionLabelKey) async {
  await tester.pumpAndSettle();
  await tester.tap(find.text(actionLabelKey));
  await tester.pumpAndSettle();
}

void main() {
  group('WorkerListItem swipe actions', () {
    late _MockRepo repo;
    late WorkerActionCubit actionCubit;

    setUp(() {
      repo = _MockRepo();
      actionCubit = WorkerActionCubit(
        deleteWorkerUseCase: DeleteWorkerUseCase(repo),
        updateWorkerStatusUseCase: UpdateWorkerStatusUseCase(repo),
      );
    });

    tearDown(() => actionCubit.close());

    testWidgets('renders worker name and caption', (tester) async {
      await _pump(tester, actionCubit: actionCubit);

      expect(find.text('Mohamed'), findsOneWidget);
      expect(find.text('Worker'), findsOneWidget);
    });

    testWidgets('swipe reveals Edit / Suspend / Delete actions', (
      tester,
    ) async {
      await _pump(tester, actionCubit: actionCubit);

      await _openSwipePane(tester);

      expect(find.bySemanticsLabel(_editLabel), findsOneWidget);
      expect(find.bySemanticsLabel(_suspendLabel), findsOneWidget);
      expect(find.bySemanticsLabel(_deleteLabel), findsOneWidget);
    });

    testWidgets('swipe reveals Unsuspend label for a suspended worker', (
      tester,
    ) async {
      await _pump(
        tester,
        actionCubit: actionCubit,
        worker: _suspendedWorker,
      );

      await _openSwipePane(tester);

      expect(find.bySemanticsLabel(_unsuspendLabel), findsOneWidget);
      expect(find.bySemanticsLabel(_suspendLabel), findsNothing);
    });

    testWidgets('Suspend swipe action confirms then calls changeStatus', (
      tester,
    ) async {
      when(
        () => repo.updateWorkerStatus('w1', WorkerStatus.inactive),
      ).thenAnswer((_) => TaskEither.of(_suspendedWorker));

      await _pump(tester, actionCubit: actionCubit);
      await _openSwipePane(tester);

      await tester.tap(find.bySemanticsLabel(_suspendLabel));
      await _confirm(tester, _confirmSuspend);

      verify(
        () => repo.updateWorkerStatus('w1', WorkerStatus.inactive),
      ).called(1);
    });

    testWidgets('Delete swipe action confirms then calls delete', (
      tester,
    ) async {
      when(
        () => repo.deleteWorker('w1'),
      ).thenAnswer((_) => TaskEither.of(unit));

      await _pump(tester, actionCubit: actionCubit);
      await _openSwipePane(tester);

      await tester.tap(find.bySemanticsLabel(_deleteLabel));
      await _confirm(tester, _confirmDelete);

      verify(() => repo.deleteWorker('w1')).called(1);
    });

    testWidgets('cancelling the confirmation sheet does not call delete', (
      tester,
    ) async {
      await _pump(tester, actionCubit: actionCubit);
      await _openSwipePane(tester);

      await tester.tap(find.bySemanticsLabel(_deleteLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_cancelLabel));
      await tester.pumpAndSettle();

      verifyNever(() => repo.deleteWorker(any()));
    });

    testWidgets('Edit swipe action navigates to the edit-worker route', (
      tester,
    ) async {
      final listBloc = WorkersListBloc(
        getWorkersUseCase: GetWorkersUseCase(repo),
      );
      addTearDown(listBloc.close);

      await _pumpWithRouter(
        tester,
        actionCubit: actionCubit,
        listBloc: listBloc,
      );
      await _openSwipePane(tester);

      await tester.tap(find.bySemanticsLabel(_editLabel));
      await tester.pumpAndSettle();

      expect(find.text('edit-worker-page'), findsOneWidget);
    });

    testWidgets('more_vert action sheet is still reachable (fallback)', (
      tester,
    ) async {
      await _pump(tester, actionCubit: actionCubit);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text(_deleteLabel), findsOneWidget);
    });
  });
}
