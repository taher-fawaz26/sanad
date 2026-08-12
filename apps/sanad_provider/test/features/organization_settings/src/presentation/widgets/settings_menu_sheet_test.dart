import 'package:account_settings/account_settings.dart';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/settings_menu_sheet.dart';
import 'package:sanad_provider/src/features/organization_settings/src/routes/organization_settings_routes.dart';

class _MockSessionManager extends Mock implements SessionManager {}

class _StubPage extends StatelessWidget {
  const _StubPage(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Scaffold(body: Text(label));
}

void main() {
  late _MockSessionManager session;

  setUp(() {
    session = _MockSessionManager();
    if (sl.isRegistered<SessionManager>()) sl.unregister<SessionManager>();
    sl.registerLazySingleton<SessionManager>(() => session);
  });

  tearDown(() {
    sl.unregister<SessionManager>();
  });

  Future<void> pumpSheetOpener(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/opener',
      routes: [
        GoRoute(
          path: '/opener',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showSettingsMenuSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: OrganizationSettingsRoutes.hub,
          builder: (context, state) => const _StubPage('hub'),
        ),
        GoRoute(
          path: OrganizationSettingsRoutes.general,
          builder: (context, state) => const _StubPage('general'),
        ),
        GoRoute(
          path: AccountSettingsRoutes.hub,
          builder: (context, state) => const _StubPage('account-settings'),
        ),
      ],
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 800),
        minTextAdapt: true,
        builder: (_, _) => MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('showSettingsMenuSheet — General Settings destination', () {
    testWidgets(
      'organization provider tapping General Settings goes to the hub',
      (tester) async {
        when(() => session.isCompany).thenReturn(true);
        await pumpSheetOpener(tester);

        await tester.tap(find.text('settings.general_settings'));
        await tester.pumpAndSettle();

        expect(find.text('hub'), findsOneWidget);
        expect(find.text('general'), findsNothing);
      },
    );

    testWidgets(
      'individual provider tapping General Settings goes directly to '
      'General Settings, skipping the hub',
      (tester) async {
        when(() => session.isCompany).thenReturn(false);
        await pumpSheetOpener(tester);

        await tester.tap(find.text('settings.general_settings'));
        await tester.pumpAndSettle();

        expect(find.text('general'), findsOneWidget);
        expect(find.text('hub'), findsNothing);
      },
    );
  });

  group('showSettingsMenuSheet — Account Settings (shared)', () {
    testWidgets('organization provider reaches the same Account Settings', (
      tester,
    ) async {
      when(() => session.isCompany).thenReturn(true);
      await pumpSheetOpener(tester);

      await tester.tap(find.text('settings.account_settings'));
      await tester.pumpAndSettle();

      expect(find.text('account-settings'), findsOneWidget);
    });

    testWidgets('individual provider reaches the same Account Settings', (
      tester,
    ) async {
      when(() => session.isCompany).thenReturn(false);
      await pumpSheetOpener(tester);

      await tester.tap(find.text('settings.account_settings'));
      await tester.pumpAndSettle();

      expect(find.text('account-settings'), findsOneWidget);
    });
  });
}
