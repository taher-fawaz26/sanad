import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:workers/src/domain/entities/invitation_entity.dart';
import 'package:workers/src/domain/entities/invitation_status.dart';
import 'package:workers/src/domain/repositories/worker_repository.dart';
import 'package:workers/src/domain/usecases/cancel_invitation_usecase.dart';
import 'package:workers/src/domain/usecases/delete_invitation_usecase.dart';
import 'package:workers/src/domain/usecases/resend_invitation_usecase.dart';
import 'package:workers/src/presentation/bloc/invitation_action/invitation_action_cubit.dart';
import 'package:workers/src/presentation/widgets/invitation_list_item.dart';

// See worker_list_item_test.dart for the full root-cause note: no
// EasyLocalization bootstrap (avoids a real SharedPreferences hang), and a
// matched design/surface size (avoids AppStatusBadge overflowing on the
// raw `.tr()` fallback key).

class _MockRepo extends Mock implements WorkerRepository {}

const _pendingInvitation = InvitationEntity(
  id: 'i1',
  fullName: 'Sara',
  role: 'Worker',
  initials: 'S',
);

const _cancelledInvitation = InvitationEntity(
  id: 'i1',
  fullName: 'Sara',
  role: 'Worker',
  initials: 'S',
  status: InvitationStatus.cancelled,
);

const _acceptedInvitation = InvitationEntity(
  id: 'i1',
  fullName: 'Sara',
  role: 'Worker',
  initials: 'S',
  status: InvitationStatus.accepted,
);

const _surfaceSize = Size(900, 1200);

Future<void> _pump(
  WidgetTester tester, {
  required InvitationActionCubit actionCubit,
  InvitationEntity invitation = _pendingInvitation,
  TextDirection direction = TextDirection.ltr,
}) async {
  await tester.binding.setSurfaceSize(_surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: _surfaceSize,
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Directionality(
          textDirection: direction,
          child: BlocProvider<InvitationActionCubit>.value(
            value: actionCubit,
            child: Scaffold(body: InvitationListItem(invitation: invitation)),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openSwipePane(WidgetTester tester, {double dx = -300}) async {
  await tester.drag(find.text('Sara'), Offset(dx, 0));
  await tester.pumpAndSettle();
}

Future<void> _confirm(WidgetTester tester, String actionLabelKey) async {
  await tester.pumpAndSettle();
  await tester.tap(find.text(actionLabelKey));
  await tester.pumpAndSettle();
}

void main() {
  group('InvitationListItem swipe actions', () {
    late _MockRepo repo;
    late InvitationActionCubit actionCubit;
    late SemanticsHandle semanticsHandle;

    setUp(() {
      repo = _MockRepo();
      actionCubit = InvitationActionCubit(
        resendInvitationUseCase: ResendInvitationUseCase(repo),
        cancelInvitationUseCase: CancelInvitationUseCase(repo),
        deleteInvitationUseCase: DeleteInvitationUseCase(repo),
      );
      semanticsHandle = WidgetsBinding.instance.ensureSemantics();
    });

    tearDown(() {
      semanticsHandle.dispose();
      actionCubit.close();
    });

    testWidgets(
      'renders invitation name and caption',
      (tester) async {
        await _pump(tester, actionCubit: actionCubit);

        expect(find.text('Sara'), findsOneWidget);
        expect(find.text('Worker'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

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

    testWidgets(
      'pending invitation: swipe reveals Copy / Resend / Cancel, not Delete',
      (tester) async {
        await _pump(tester, actionCubit: actionCubit);

        await _openSwipePane(tester);

        expect(
          find.bySemanticsLabel('workers.invitation_action_copy_link'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('workers.invitation_action_resend'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('workers.invitation_action_cancel'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('workers.invitation_action_delete'),
          findsNothing,
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'cancelled invitation: swipe reveals Copy / Resend / Delete, not Cancel',
      (tester) async {
        await _pump(
          tester,
          actionCubit: actionCubit,
          invitation: _cancelledInvitation,
        );

        await _openSwipePane(tester);

        expect(
          find.bySemanticsLabel('workers.invitation_action_copy_link'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('workers.invitation_action_resend'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('workers.invitation_action_delete'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('workers.invitation_action_cancel'),
          findsNothing,
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'accepted invitation: swipe reveals only Copy',
      (tester) async {
        await _pump(
          tester,
          actionCubit: actionCubit,
          invitation: _acceptedInvitation,
        );

        await _openSwipePane(tester);

        expect(
          find.bySemanticsLabel('workers.invitation_action_copy_link'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('workers.invitation_action_resend'),
          findsNothing,
        );
        expect(
          find.bySemanticsLabel('workers.invitation_action_cancel'),
          findsNothing,
        );
        expect(
          find.bySemanticsLabel('workers.invitation_action_delete'),
          findsNothing,
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'Copy swipe action copies the link without a confirmation sheet',
      (tester) async {
        final log = <MethodCall>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            log.add(call);
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );

        await _pump(tester, actionCubit: actionCubit);
        await _openSwipePane(tester);

        await tester.tap(
          find.bySemanticsLabel('workers.invitation_action_copy_link'),
        );
        await tester.pumpAndSettle();

        expect(
          log.any((c) => c.method == 'Clipboard.setData'),
          isTrue,
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'Resend swipe action confirms then calls resend',
      (tester) async {
        when(
          () => repo.resendInvitation('i1'),
        ).thenAnswer((_) => TaskEither.of(unit));

        await _pump(tester, actionCubit: actionCubit);
        await _openSwipePane(tester);

        await tester.tap(
          find.bySemanticsLabel('workers.invitation_action_resend'),
        );
        await _confirm(tester, 'workers.invitation_resend_action');

        verify(() => repo.resendInvitation('i1')).called(1);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'Cancel swipe action confirms then calls cancel',
      (tester) async {
        when(
          () => repo.cancelInvitation('i1'),
        ).thenAnswer((_) => TaskEither.of(unit));

        await _pump(tester, actionCubit: actionCubit);
        await _openSwipePane(tester);

        await tester.tap(
          find.bySemanticsLabel('workers.invitation_action_cancel'),
        );
        await _confirm(tester, 'workers.invitation_cancel_action');

        verify(() => repo.cancelInvitation('i1')).called(1);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'Delete swipe action confirms then calls delete',
      (tester) async {
        when(
          () => repo.deleteInvitation('i1'),
        ).thenAnswer((_) => TaskEither.of(unit));

        await _pump(
          tester,
          actionCubit: actionCubit,
          invitation: _cancelledInvitation,
        );
        await _openSwipePane(tester);

        await tester.tap(
          find.bySemanticsLabel('workers.invitation_action_delete'),
        );
        await _confirm(tester, 'workers.invitation_delete_action');

        verify(() => repo.deleteInvitation('i1')).called(1);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'cancelling the confirmation sheet does not call cancel',
      (tester) async {
        await _pump(tester, actionCubit: actionCubit);
        await _openSwipePane(tester);

        await tester.tap(
          find.bySemanticsLabel('workers.invitation_action_cancel'),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('workers.cancel'));
        await tester.pumpAndSettle();

        verifyNever(() => repo.cancelInvitation(any()));
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'RTL: dragging start-to-end reveals all actions without breaking layout',
      (tester) async {
        await _pump(
          tester,
          actionCubit: actionCubit,
          direction: TextDirection.rtl,
        );

        // In RTL the logical "end" pane is revealed by dragging left-to-right
        // — same AppSwipeActions convention verified in design_system's own
        // app_swipe_actions_test.dart.
        await _openSwipePane(tester, dx: 300);

        expect(
          find.bySemanticsLabel('workers.invitation_action_copy_link'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('workers.invitation_action_resend'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('workers.invitation_action_cancel'),
          findsOneWidget,
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });
}
