import 'package:branches/branches.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_provider/src/features/home/src/presentation/widgets/home_quick_actions.dart';
import 'package:services/services.dart';
import 'package:testing/testing.dart';
import 'package:workers/workers.dart';

import '../../../../../support/fake_authorization_reader.dart';
import '../../../../../support/fake_session_manager.dart';

// No EasyLocalization bootstrap in this sandboxed test environment — `.tr()`
// falls back to the raw key, so labels are matched by key text.

class _FakePage extends StatelessWidget {
  const _FakePage(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Scaffold(body: Text(label));
}

const _homeRoute = '/home';

Future<void> _pumpQuickActions(WidgetTester tester) async {
  final router = GoRouter(
    initialLocation: _homeRoute,
    routes: [
      GoRoute(
        path: _homeRoute,
        builder: (context, state) => const Scaffold(
          body: SingleChildScrollView(child: HomeQuickActions()),
        ),
      ),
      GoRoute(
        path: ServiceRoutes.add,
        builder: (context, state) => const _FakePage('add-service'),
      ),
      GoRoute(
        path: BranchRoutes.add,
        builder: (context, state) => const _FakePage('add-branch'),
      ),
      GoRoute(
        path: WorkerRoutes.add,
        builder: (context, state) => const _FakePage('invite-member'),
      ),
      GoRoute(
        path: ServiceRoutes.requestNew,
        builder: (context, state) => const _FakePage('new-request'),
      ),
    ],
  );

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: testDesignSize,
      minTextAdapt: true,
      builder: (_, _) =>
          MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() {
    unregisterFakeSessionManager();
    unregisterFakeAuthorizationReader();
  });

  group('as a provider owner with branch-create permission', () {
    setUp(() {
      registerFakeSessionManager();
      registerFakeAuthorizationReader(permissions: [BranchPermissions.create]);
    });

    testWidgets('all four actions are visible', (tester) async {
      await _pumpQuickActions(tester);

      expect(find.text('home.action_add_service'), findsOneWidget);
      expect(find.text('home.action_add_branch'), findsOneWidget);
      expect(find.text('home.action_invite_member'), findsOneWidget);
      expect(find.text('home.action_new_request'), findsOneWidget);
    });

    testWidgets('Add Service navigates to the existing Add Service route', (
      tester,
    ) async {
      await _pumpQuickActions(tester);

      await tester.ensureVisible(find.text('home.action_add_service'));
      await tester.tap(find.text('home.action_add_service'));
      await tester.pumpAndSettle();

      expect(find.text('add-service'), findsOneWidget);
    });

    testWidgets('Add Branch navigates to the existing Add Branch route', (
      tester,
    ) async {
      await _pumpQuickActions(tester);

      await tester.ensureVisible(find.text('home.action_add_branch'));
      await tester.tap(find.text('home.action_add_branch'));
      await tester.pumpAndSettle();

      expect(find.text('add-branch'), findsOneWidget);
    });

    testWidgets('Invite Member navigates to the existing invite route', (
      tester,
    ) async {
      await _pumpQuickActions(tester);

      await tester.ensureVisible(find.text('home.action_invite_member'));
      await tester.tap(find.text('home.action_invite_member'));
      await tester.pumpAndSettle();

      expect(find.text('invite-member'), findsOneWidget);
    });

    testWidgets('New Request navigates to the existing request-new route', (
      tester,
    ) async {
      await _pumpQuickActions(tester);

      await tester.ensureVisible(find.text('home.action_new_request'));
      await tester.tap(find.text('home.action_new_request'));
      await tester.pumpAndSettle();

      expect(find.text('new-request'), findsOneWidget);
    });
  });

  group('as a non-owner without branch-create permission', () {
    setUp(() {
      registerFakeSessionManager(isProvider: false);
      registerFakeAuthorizationReader();
    });

    testWidgets(
      'owner-only actions are hidden and Add Branch is hidden too',
      (tester) async {
        await _pumpQuickActions(tester);

        expect(find.text('home.action_add_service'), findsNothing);
        expect(find.text('home.action_add_branch'), findsNothing);
        expect(find.text('home.action_invite_member'), findsNothing);
        expect(find.text('home.action_new_request'), findsNothing);
      },
    );
  });
}
