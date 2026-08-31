import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_client/src/features/oauth/oauth_routes.dart';
import 'package:sanad_client/src/features/oauth/oauth_screen.dart';
import 'package:sanad_client/src/features/oauth/oauth_splash_page.dart';

import 'oauth_test_harness.dart';

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
  ],
);

void main() {
  testWidgets('renders without throwing', (tester) async {
    await pumpOAuthRouter(tester, _buildRouter());

    expect(find.byType(OAuthSplashPage), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Let the pending navigation timer resolve before the test ends.
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });

  testWidgets('navigates to OAuthScreen after the entry delay', (
    tester,
  ) async {
    await pumpOAuthRouter(tester, _buildRouter());
    expect(find.byType(OAuthSplashPage), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.byType(OAuthScreen), findsOneWidget);
    expect(find.byType(OAuthSplashPage), findsNothing);
  });
}
