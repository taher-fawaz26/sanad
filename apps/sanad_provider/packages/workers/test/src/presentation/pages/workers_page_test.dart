import 'package:core/core.dart' as core show Page;
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:workers/src/domain/repositories/worker_repository.dart';
import 'package:workers/src/domain/usecases/cancel_invitation_usecase.dart';
import 'package:workers/src/domain/usecases/delete_invitation_usecase.dart';
import 'package:workers/src/domain/usecases/delete_worker_usecase.dart';
import 'package:workers/src/domain/usecases/get_invitations_usecase.dart';
import 'package:workers/src/domain/usecases/get_workers_usecase.dart';
import 'package:workers/src/domain/usecases/resend_invitation_usecase.dart';
import 'package:workers/src/domain/usecases/update_worker_status_usecase.dart';
import 'package:workers/src/presentation/bloc/invitation_action/invitation_action_cubit.dart';
import 'package:workers/src/presentation/bloc/invitations_list/invitations_list_bloc.dart';
import 'package:workers/src/presentation/bloc/worker_action/worker_action_cubit.dart';
import 'package:workers/src/presentation/bloc/workers_list/workers_list_bloc.dart';
import 'package:workers/src/presentation/pages/workers_page.dart';

// No EasyLocalization bootstrap (avoids a real SharedPreferences hang in this
// sandboxed test environment) — `.tr()` calls fall back to the raw key.

class _MockWorkerRepository extends Mock implements WorkerRepository {}

void main() {
  late _MockWorkerRepository repo;

  setUpAll(() {
    registerFallbackValue(const WorkersQuery());
  });

  setUp(() {
    repo = _MockWorkerRepository();
    when(
      () => repo.getWorkers(any()),
    ).thenAnswer((_) => TaskEither.of(const core.Page.empty()));
  });

  Future<void> pump(WidgetTester tester, {required bool isOwner}) async {
    await tester.binding.setSurfaceSize(const Size(1080, 2400));
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final workersListBloc = WorkersListBloc(
      getWorkersUseCase: GetWorkersUseCase(repo),
    );
    final workerActionCubit = WorkerActionCubit(
      deleteWorkerUseCase: DeleteWorkerUseCase(repo),
      updateWorkerStatusUseCase: UpdateWorkerStatusUseCase(repo),
    );
    // Only constructed for an owner — mirrors WorkersModule.route, which
    // never provides either bloc for a non-owner (RBAC Phase 7F). Proves
    // the page never reads them for a non-owner: if it tried, this would
    // fail with a "provider not found" error rather than an assertion
    // mismatch.
    final invitationsListBloc = isOwner
        ? InvitationsListBloc(
            getInvitationsUseCase: GetInvitationsUseCase(repo),
          )
        : null;
    final invitationActionCubit = isOwner
        ? InvitationActionCubit(
            resendInvitationUseCase: ResendInvitationUseCase(repo),
            cancelInvitationUseCase: CancelInvitationUseCase(repo),
            deleteInvitationUseCase: DeleteInvitationUseCase(repo),
          )
        : null;
    addTearDown(() {
      workersListBloc.close();
      workerActionCubit.close();
      invitationsListBloc?.close();
      invitationActionCubit?.close();
    });

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 800),
        minTextAdapt: true,
        builder: (_, _) => MaterialApp(
          theme: AppTheme.light(),
          home: MultiBlocProvider(
            providers: [
              BlocProvider<WorkersListBloc>.value(value: workersListBloc),
              BlocProvider<WorkerActionCubit>.value(value: workerActionCubit),
              if (invitationsListBloc != null)
                BlocProvider<InvitationsListBloc>.value(
                  value: invitationsListBloc,
                ),
              if (invitationActionCubit != null)
                BlocProvider<InvitationActionCubit>.value(
                  value: invitationActionCubit,
                ),
            ],
            child: WorkersPage(isOwner: isOwner),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('isOwner: true', () {
    testWidgets('shows the Team / Invitations / Roles segmented control', (
      tester,
    ) async {
      await pump(tester, isOwner: true);

      expect(find.byType(AppSegmentedControl<int>), findsOneWidget);
    });

    testWidgets(
      'shows an Add team action — both the footer button and the '
      "empty-state's own action render it, since the team list is empty",
      (tester) async {
        await pump(tester, isOwner: true);

        expect(find.text('workers.add_team'), findsNWidgets(2));
      },
    );
  });

  group(
    'isOwner: false (RBAC Phase 7F — invitations/roles are owner-only)',
    () {
      testWidgets(
        'renders the Team list without InvitationsListBloc or '
        'InvitationActionCubit provided anywhere in the tree',
        (tester) async {
          await pump(tester, isOwner: false);

          expect(find.byType(WorkersPage), findsOneWidget);
        },
      );

      testWidgets(
        'shows no segmented control — Invitations and Roles are the only '
        'other tabs, and both are owner-only',
        (tester) async {
          await pump(tester, isOwner: false);

          expect(find.byType(AppSegmentedControl<int>), findsNothing);
        },
      );

      testWidgets(
        'shows no Add team footer — inviting a worker is itself owner-only '
        '(RBAC Phase 7E)',
        (tester) async {
          await pump(tester, isOwner: false);

          expect(find.text('workers.add_team'), findsNothing);
        },
      );
    },
  );
}
