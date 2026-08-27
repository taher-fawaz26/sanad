import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_client/src/features/onboarding/get_started_page.dart';
import 'package:sanad_client/src/features/onboarding/onboarding_routes.dart';
import 'package:sanad_client/src/features/onboarding/splash_page.dart';

import 'onboarding_test_harness.dart';

GoRouter _buildRouter() => GoRouter(
  initialLocation: OnboardingRoutes.splash,
  routes: [
    GoRoute(
      path: OnboardingRoutes.splash,
      builder: (context, state) => const OnboardingSplashPage(),
    ),
    GoRoute(
      path: OnboardingRoutes.getStarted,
      builder: (context, state) => const GetStartedPage(),
    ),
  ],
);

void main() {
  testWidgets('renders without throwing', (tester) async {
    await pumpOnboardingRouter(tester, _buildRouter());

    expect(find.byType(OnboardingSplashPage), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Let the pending navigation timer resolve before the test ends.
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });

  testWidgets('navigates to GetStartedPage after the entry delay', (
    tester,
  ) async {
    await pumpOnboardingRouter(tester, _buildRouter());
    expect(find.byType(OnboardingSplashPage), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.byType(GetStartedPage), findsOneWidget);
    expect(find.byType(OnboardingSplashPage), findsNothing);
  });
}
