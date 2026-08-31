// No EasyLocalization bootstrap — `.tr()` falls back to the raw key, so
// assertions match on raw i18n keys (see oauth_test_harness.dart).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_client/src/features/oauth/oauth_routes.dart';
import 'package:sanad_client/src/features/oauth/oauth_screen.dart';
import 'package:sanad_client/src/features/oauth/oauth_uae_pass_page.dart';
import 'package:sanad_client/src/features/oauth/oauth_uae_pass_waiting_page.dart';

import 'oauth_test_harness.dart';

Future<void> _pumpAtWaitingScreen(WidgetTester tester) async {
  // Starts at OAuthScreen and taps through Continue-in-UAE-PASS to the
  // waiting screen, mirroring oauth_uae_pass_page_test.dart's own real-tap
  // navigation convention.
  final router = GoRouter(
    initialLocation: OAuthRoutes.screen,
    routes: [
      GoRoute(
        path: OAuthRoutes.screen,
        builder: (context, state) => const OAuthScreen(),
      ),
      GoRoute(
        path: OAuthRoutes.uaePass,
        builder: (context, state) => const OAuthUaePassPage(),
      ),
      GoRoute(
        path: OAuthRoutes.uaePassWaiting,
        builder: (context, state) => const OAuthUaePassWaitingPage(),
      ),
    ],
  );

  await pumpOAuthRouter(tester, router);
  await tester.tap(find.text('oauth.continue_uae_pass'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('oauth.open_uae_pass'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'renders back button, mark, title, subtitle and both buttons',
    (tester) async {
      await _pumpAtWaitingScreen(tester);

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.text('oauth.uae_pass_waiting_title'), findsOneWidget);
      expect(find.text('oauth.uae_pass_waiting_subtitle'), findsOneWidget);
      expect(find.text('oauth.open_uae_pass_again'), findsOneWidget);
      expect(find.text('common.cancel'), findsOneWidget);
    },
  );

  testWidgets('tapping Open UAE PASS again does not throw (no backend yet)', (
    tester,
  ) async {
    await _pumpAtWaitingScreen(tester);

    await tester.tap(find.text('oauth.open_uae_pass_again'));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping cancel pops back to the previous screen', (
    tester,
  ) async {
    await _pumpAtWaitingScreen(tester);

    await tester.tap(find.text('common.cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(OAuthUaePassPage), findsOneWidget);
    expect(find.byType(OAuthUaePassWaitingPage), findsNothing);
  });

  testWidgets('renders correctly under RTL', (tester) async {
    await pumpOAuth(
      tester,
      const Directionality(
        textDirection: TextDirection.rtl,
        child: OAuthUaePassWaitingPage(),
      ),
    );

    expect(find.text('oauth.uae_pass_waiting_title'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
