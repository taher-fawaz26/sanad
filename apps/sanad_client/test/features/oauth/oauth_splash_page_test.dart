import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sanad_client/src/features/account_setup/account_setup_routes.dart';
import 'package:sanad_client/src/features/oauth/oauth_routes.dart';
import 'package:sanad_client/src/features/oauth/oauth_screen.dart';
import 'package:sanad_client/src/features/oauth/oauth_splash_page.dart';
import 'package:sanad_client/src/routing/client_routes.dart';

import '../../support/client_auth_test_locator.dart';
import 'oauth_test_harness.dart';

/// The splash decides where to go from the session that
/// `SessionManager.restore()` already rehydrated during bootstrap. These tests
/// drive that decision through the real `AuthStatusNotifier` + a mocked
/// `SessionManager`, the same lifecycle the app uses — no parallel state.
GoRouter _buildRouter() => GoRouter(
  initialLocation: OAuthRoutes.splash,
  routes: [
    GoRoute(
      path: OAuthRoutes.splash,
      builder: (context, state) => const OAuthSplashPage(),
    ),
    GoRoute(
      path: OAuthRoutes.screen,
      builder: (context, state) => const OAuthScreen(),
    ),
    GoRoute(
      path: AccountSetupRoutes.enterName,
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('enter-name'))),
    ),
    GoRoute(
      path: ClientRoutes.home,
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('home'))),
    ),
  ],
);

void main() {
  late AuthStatusNotifier authStatus;
  late MockSessionManager session;

  setUp(() {
    authStatus = AuthStatusNotifier();
    session = MockSessionManager();
    when(() => session.displayName).thenReturn(null);
    sl
      ..registerSingleton<AuthStatusNotifier>(authStatus)
      ..registerSingleton<SessionManager>(session);
  });

  tearDown(() {
    sl
      ..unregister<AuthStatusNotifier>()
      ..unregister<SessionManager>();
  });

  testWidgets('builds and hands off without throwing', (tester) async {
    await pumpOAuthRouter(tester, _buildRouter());
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // The splash navigates as soon as the already-restored auth state is
    // known, rather than lingering on an artificial timer (the entrance
    // animation runs in parallel and never blocks the hand-off). With no
    // session it hands off to the OAuth entry screen, without throwing.
    expect(tester.takeException(), isNull);
    expect(find.byType(OAuthScreen), findsOneWidget);
    expect(find.byType(OAuthSplashPage), findsNothing);
  });

  testWidgets('signed out → OAuth entry screen', (tester) async {
    authStatus.update(AuthStatus.unauthenticated);

    await pumpOAuthRouter(tester, _buildRouter());
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.byType(OAuthScreen), findsOneWidget);
    expect(find.byType(OAuthSplashPage), findsNothing);
  });

  testWidgets('restored session with a name → Home', (tester) async {
    authStatus.update(AuthStatus.authenticated, isProfileCompleted: true);
    when(() => session.displayName).thenReturn('Sara');

    await pumpOAuthRouter(tester, _buildRouter());
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('home'), findsOneWidget);
    expect(find.byType(OAuthScreen), findsNothing);
  });

  testWidgets('restored session with no name yet → Enter Name', (tester) async {
    // ACTIVE session whose profile setup never finished (name still null):
    // resume it instead of dropping into an app with no name, and instead of
    // sending an authenticated user back to the Get Started screen.
    authStatus.update(AuthStatus.authenticated, isProfileCompleted: false);
    when(() => session.displayName).thenReturn(null);

    await pumpOAuthRouter(tester, _buildRouter());
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('enter-name'), findsOneWidget);
    expect(find.byType(OAuthScreen), findsNothing);
  });
}
