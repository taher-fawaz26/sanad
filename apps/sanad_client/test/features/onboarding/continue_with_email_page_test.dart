// No EasyLocalization bootstrap — `.tr()` falls back to the raw key, so
// assertions match on raw i18n keys (see onboarding_test_harness.dart /
// auth_page_test.dart for the same convention).

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_client/src/features/onboarding/continue_with_email_page.dart';
import 'package:sanad_client/src/features/onboarding/get_started_page.dart';
import 'package:sanad_client/src/features/onboarding/onboarding_routes.dart';

import 'onboarding_test_harness.dart';

Finder _nextButtonFinder() => find.widgetWithText(AppButton, 'onboarding.next');

Future<void> _pumpAtEmailScreen(WidgetTester tester) async {
  // Starts at GetStartedPage and pushes to the email screen, mirroring the
  // real app's navigation stack — ContinueWithEmailPage's back chevron calls
  // context.pop(), which needs a previous page to return to.
  final router = GoRouter(
    initialLocation: OnboardingRoutes.getStarted,
    routes: [
      GoRoute(
        path: OnboardingRoutes.getStarted,
        builder: (context, state) => const GetStartedPage(),
      ),
      GoRoute(
        path: OnboardingRoutes.continueWithEmail,
        builder: (context, state) => const ContinueWithEmailPage(),
      ),
    ],
  );

  await pumpOnboardingRouter(tester, router);
  await router.push(OnboardingRoutes.continueWithEmail);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders back button, icon, title/subtitle and email field', (
    tester,
  ) async {
    await _pumpAtEmailScreen(tester);

    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(find.text('onboarding.email_title'), findsOneWidget);
    expect(find.text('onboarding.email_subtitle'), findsOneWidget);
    expect(find.text('onboarding.email_label'), findsOneWidget);
    expect(_nextButtonFinder(), findsOneWidget);
  });

  testWidgets('Next is disabled while the email field is empty', (
    tester,
  ) async {
    await _pumpAtEmailScreen(tester);

    final button = tester.widget<AppButton>(_nextButtonFinder());
    expect(button.onPressed, isNull);
  });

  testWidgets('Next stays disabled for an invalid email', (tester) async {
    await _pumpAtEmailScreen(tester);

    await tester.enterText(find.byType(TextField), 'not-an-email');
    await tester.pump();

    final button = tester.widget<AppButton>(_nextButtonFinder());
    expect(button.onPressed, isNull);
  });

  testWidgets('Next is enabled for a valid email', (tester) async {
    await _pumpAtEmailScreen(tester);

    await tester.enterText(find.byType(TextField), 'user@example.com');
    await tester.pump();

    final button = tester.widget<AppButton>(_nextButtonFinder());
    expect(button.onPressed, isNotNull);
  });

  testWidgets('tapping back pops to the previous screen', (tester) async {
    await _pumpAtEmailScreen(tester);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.byType(GetStartedPage), findsOneWidget);
    expect(find.byType(ContinueWithEmailPage), findsNothing);
  });

  testWidgets('renders correctly under RTL', (tester) async {
    await pumpOnboarding(
      tester,
      const Directionality(
        textDirection: TextDirection.rtl,
        child: ContinueWithEmailPage(),
      ),
    );

    expect(find.text('onboarding.email_title'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
