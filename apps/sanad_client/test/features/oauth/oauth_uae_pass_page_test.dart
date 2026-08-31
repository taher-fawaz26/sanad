// No EasyLocalization bootstrap — `.tr()` falls back to the raw key, so
// assertions match on raw i18n keys (see oauth_test_harness.dart /
// auth_page_test.dart for the same convention).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_client/src/features/oauth/oauth_routes.dart';
import 'package:sanad_client/src/features/oauth/oauth_screen.dart';
import 'package:sanad_client/src/features/oauth/oauth_uae_pass_page.dart';
import 'package:sanad_client/src/features/oauth/oauth_uae_pass_waiting_page.dart';

import 'oauth_test_harness.dart';

Future<void> _pumpAtUaePassScreen(WidgetTester tester) async {
  // Starts at OAuthScreen and taps through to the UAE PASS screen, mirroring
  // the real app's navigation stack — driven via a real tap (not a raw
  // router.push) to match the one navigation pattern already verified
  // stable in oauth_screen_test.dart.
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
}

void main() {
  testWidgets(
    'renders back button, illustration, title, subtitle and Open button',
    (tester) async {
      await _pumpAtUaePassScreen(tester);

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.text('UAE PASS'), findsOneWidget);
      expect(find.text('oauth.uae_pass_title'), findsOneWidget);
      expect(find.text('oauth.uae_pass_subtitle'), findsOneWidget);
      expect(find.text('oauth.open_uae_pass'), findsOneWidget);
    },
  );

  testWidgets('tapping Open UAE PASS navigates to the waiting screen', (
    tester,
  ) async {
    await _pumpAtUaePassScreen(tester);

    await tester.tap(find.text('oauth.open_uae_pass'));
    await tester.pumpAndSettle();

    expect(find.byType(OAuthUaePassWaitingPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping back pops to the previous screen', (tester) async {
    await _pumpAtUaePassScreen(tester);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.byType(OAuthScreen), findsOneWidget);
    expect(find.byType(OAuthUaePassPage), findsNothing);
  });

  testWidgets('renders correctly under RTL', (tester) async {
    await pumpOAuth(
      tester,
      const Directionality(
        textDirection: TextDirection.rtl,
        child: OAuthUaePassPage(),
      ),
    );

    expect(find.text('oauth.uae_pass_title'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
