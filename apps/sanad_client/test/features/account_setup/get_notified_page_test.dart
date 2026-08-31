// No EasyLocalization bootstrap — `.tr()` falls back to the raw key, so
// assertions match on raw i18n keys (see oauth_test_harness.dart /
// auth_page_test.dart for the same convention).

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_client/src/features/account_setup/get_notified_page.dart';
import 'package:sanad_client/src/routing/client_routes.dart';

import '../oauth/oauth_test_harness.dart';

Future<void> _pumpGetNotified(WidgetTester tester) =>
    pumpOAuth(tester, const GetNotifiedPage());

/// A router that hosts Get Notified plus a placeholder Home, so the "enter the
/// app" actions have a real destination to navigate to.
Future<void> _pumpWithHome(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1080, 2400));
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final router = GoRouter(
    initialLocation: '/get-notified',
    routes: [
      GoRoute(
        path: '/get-notified',
        builder: (context, state) => const GetNotifiedPage(),
      ),
      GoRoute(
        path: ClientRoutes.home,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('home'))),
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'renders back button, Skip, icon, title, subtitle, illustration, '
    'button and helper text',
    (tester) async {
      await _pumpGetNotified(tester);

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.text('common.skip'), findsOneWidget);
      expect(find.text('get_notified.title'), findsOneWidget);
      expect(find.text('get_notified.subtitle'), findsOneWidget);
      expect(
        find.widgetWithText(AppButton, 'get_notified.turn_on_button'),
        findsOneWidget,
      );
      expect(find.text('get_notified.helper_text'), findsOneWidget);
    },
  );

  testWidgets(
    'renders the three real notification preview cards, not a generic '
    'placeholder',
    (tester) async {
      await _pumpGetNotified(tester);

      expect(find.text('get_notified.preview_document_title'), findsOneWidget);
      expect(find.text('get_notified.preview_document_body'), findsOneWidget);
      expect(find.text('get_notified.preview_document_time'), findsOneWidget);
      expect(find.text('get_notified.preview_offer_title'), findsOneWidget);
      expect(find.text('get_notified.preview_offer_body'), findsOneWidget);
      expect(find.text('get_notified.preview_offer_time'), findsOneWidget);
      expect(find.text('get_notified.preview_id_title'), findsOneWidget);
      expect(find.text('get_notified.preview_id_body'), findsOneWidget);
      expect(find.text('get_notified.preview_id_time'), findsOneWidget);
    },
  );

  testWidgets('tapping Skip enters the app (navigates to Home)', (
    tester,
  ) async {
    await _pumpWithHome(tester);

    await tester.tap(find.text('common.skip'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(GetNotifiedPage), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('tapping Turn On Notifications enters the app (navigates to '
      'Home)', (tester) async {
    await _pumpWithHome(tester);

    await tester.tap(
      find.widgetWithText(AppButton, 'get_notified.turn_on_button'),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(GetNotifiedPage), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('tapping back pops the page', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1080, 2400));
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // GetNotifiedPage's back chevron calls go_router's context.pop(), which
    // needs a real GoRouter ancestor with a previous location to return to
    // — a raw Navigator.push() here throws (same lesson as
    // oauth_otp_page_test.dart's own back-navigation test).
    final router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.push('/get-notified'),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/get-notified',
          builder: (context, state) => const GetNotifiedPage(),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(GetNotifiedPage), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.byType(GetNotifiedPage), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('renders correctly under RTL', (tester) async {
    await pumpOAuth(
      tester,
      const Directionality(
        textDirection: TextDirection.rtl,
        child: GetNotifiedPage(),
      ),
    );

    expect(find.text('get_notified.title'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without overflow on a small-height surface', (
    tester,
  ) async {
    // setSurfaceSize and physicalSize must carry the SAME raw value (matching
    // oauth_test_harness.dart's convention) — a mismatch between them
    // desyncs the actual render width from what MediaQuery reports.
    await tester.binding.setSurfaceSize(const Size(1080, 1680));
    tester.view.physicalSize = const Size(1080, 1680);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const GetNotifiedPage()),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.widgetWithText(AppButton, 'get_notified.turn_on_button'),
      findsOneWidget,
    );
  });
}
