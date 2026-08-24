// Delete-account details page: entry loads eligibility and shows the details
// page (never auto-opens OTP); the Type-DELETE gate + Delete button are the
// confirmation (no generic confirmation sheet); an already-pending request is
// non-blocking. EasyLocalization is not bootstrapped, so `.tr()` falls back to
// raw keys — assertions use the key strings.
import 'package:account_settings/src/domain/entities/account_deletion_eligibility.dart';
import 'package:account_settings/src/domain/entities/deletion_blocker.dart';
import 'package:account_settings/src/domain/entities/deletion_cascade_preview.dart';
import 'package:account_settings/src/domain/enums/deletion_blocker_code.dart';
import 'package:account_settings/src/domain/enums/deletion_persona.dart';
import 'package:account_settings/src/presentation/bloc/account_deletion/account_deletion_bloc.dart';
import 'package:account_settings/src/presentation/pages/account_deletion_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_ui/shared_ui.dart';

class _MockAccountDeletionBloc
    extends MockBloc<AccountDeletionEvent, AccountDeletionState>
    implements AccountDeletionBloc {}

const _ownerCascade = DeletionCascadePreview(
  persona: DeletionPersona.companyProvider,
  branches: 2,
  services: 8,
  teamAccounts: 4,
  invitations: 4,
  documents: 1,
  media: 38,
  branchesUnassigned: 0,
);

AccountDeletionState _eligible({List<DeletionBlocker> blockers = const []}) =>
    AccountDeletionState(
      eligibilityStatus: RequestStatus.success,
      eligibility: AccountDeletionEligibility(
        isEligible: blockers.isEmpty,
        gracePeriodDays: 14,
        blockers: blockers,
        warnings: const [],
        cascadePreview: _ownerCascade,
      ),
    );

const _alreadyPending = DeletionBlocker(
  code: DeletionBlockerCode.alreadyPendingDeletion,
  rawCode: 'ALREADY_PENDING_DELETION',
  message: 'A deletion request is already in progress.',
);

Future<void> _pumpPage(WidgetTester tester, AccountDeletionBloc bloc) async {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => BlocProvider<AccountDeletionBloc>.value(
          value: bloc,
          child: const AccountDeletionPage(),
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(400, 800),
      builder: (_, _) => MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    registerFallbackValue(const AccountDeletionStarted());
    registerFallbackValue(const AccountDeletionEligibilityRequested());
  });

  late _MockAccountDeletionBloc bloc;

  setUp(() {
    bloc = _MockAccountDeletionBloc();
    whenListen(
      bloc,
      const Stream<AccountDeletionState>.empty(),
      initialState: _eligible(),
    );
  });

  testWidgets('entry loads eligibility (not status-resume)', (tester) async {
    await _pumpPage(tester, bloc);
    verify(
      () => bloc.add(const AccountDeletionEligibilityRequested()),
    ).called(1);
    verifyNever(() => bloc.add(const AccountDeletionStatusRequested()));
  });

  testWidgets(
    'owner must type DELETE before the destructive button enables',
    (tester) async {
      await _pumpPage(tester, bloc);

      final deleteButton = find.widgetWithText(
        AppButton,
        'account_deletion.delete_button',
      );
      expect(deleteButton, findsOneWidget);
      expect(
        tester.widget<AppButton>(deleteButton).onPressed,
        isNull,
        reason: 'Delete is disabled until DELETE is typed',
      );

      await tester.enterText(find.byType(TextField), 'DELETE');
      await tester.pump();

      expect(
        tester.widget<AppButton>(deleteButton).onPressed,
        isNotNull,
        reason: 'Delete enables once DELETE is typed exactly',
      );
    },
  );

  testWidgets(
    'tapping Delete starts deletion directly — no confirmation sheet',
    (tester) async {
      await _pumpPage(tester, bloc);

      await tester.enterText(find.byType(TextField), 'DELETE');
      await tester.pump();

      final deleteButton = find.widgetWithText(
        AppButton,
        'account_deletion.delete_button',
      );
      await tester.ensureVisible(deleteButton);
      await tester.pumpAndSettle();
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // No generic confirmation sheet — the Type-DELETE gate is the guard.
      expect(find.byType(AppConfirmationContent), findsNothing);
      expect(find.text('account_deletion.confirm_sheet_title'), findsNothing);
      // The start event fires immediately, exactly once.
      verify(() => bloc.add(const AccountDeletionStarted())).called(1);
    },
  );

  testWidgets(
    'an already-pending request is non-blocking — details still render',
    (tester) async {
      whenListen(
        bloc,
        const Stream<AccountDeletionState>.empty(),
        initialState: _eligible(blockers: const [_alreadyPending]),
      );
      await _pumpPage(tester, bloc);

      // The details (Type-DELETE field + Delete button) render rather than the
      // blocked state — the user can resume via the idempotent Delete tap.
      expect(find.byType(TextField), findsOneWidget);
      expect(
        find.widgetWithText(AppButton, 'account_deletion.delete_button'),
        findsOneWidget,
      );
      expect(find.text('account_deletion.blocked_title'), findsNothing);
    },
  );

  testWidgets(
    'a hard blocker (last active super admin) blocks the flow',
    (tester) async {
      whenListen(
        bloc,
        const Stream<AccountDeletionState>.empty(),
        initialState: _eligible(
          blockers: const [
            DeletionBlocker(
              code: DeletionBlockerCode.lastActiveSuperAdmin,
              rawCode: 'LAST_ACTIVE_SUPER_ADMIN',
              message: 'You are the last active super admin.',
            ),
          ],
        ),
      );
      await _pumpPage(tester, bloc);

      expect(find.text('account_deletion.blocked_title'), findsOneWidget);
      expect(
        find.widgetWithText(AppButton, 'account_deletion.delete_button'),
        findsNothing,
      );
    },
  );
}
