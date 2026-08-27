// No EasyLocalization bootstrap in this test harness — `.tr()` falls back
// to the raw key (see onboarding_test_harness.dart / auth_page_test.dart
// for the same convention). Assertions match on raw i18n keys.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_client/src/features/onboarding/continue_with_email_page.dart';
import 'package:sanad_client/src/features/onboarding/get_started_page.dart';
import 'package:sanad_client/src/features/onboarding/onboarding_routes.dart';

import 'onboarding_test_harness.dart';

GoRouter _buildRouter() => GoRouter(
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

void main() {
  testWidgets('renders title, subtitle and all four sign-in actions', (
    tester,
  ) async {
    await pumpOnboarding(tester, const GetStartedPage());

    expect(find.text('onboarding.get_started_title'), findsOneWidget);
    expect(find.text('onboarding.get_started_subtitle'), findsOneWidget);
    expect(find.text('onboarding.continue_uae_pass'), findsOneWidget);
    expect(find.text('onboarding.continue_email'), findsOneWidget);
    expect(find.text('onboarding.continue_google'), findsOneWidget);
    expect(find.text('onboarding.continue_phone'), findsOneWidget);
    // Text.rich has no `.data`, so find.text can't match a span directly —
    // check the composed RichText's plain-text content instead.
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('onboarding.terms_link'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('language selector shows both language options', (
    tester,
  ) async {
    // Only opens the menu — doesn't select an option. Selecting calls
    // easy_localization's context.setLocale(), which needs a live
    // EasyLocalization ancestor; bootstrapping that hangs in this repo's
    // widget-test sandbox (see onboarding_test_harness.dart), so the actual
    // locale-sync behavior is verified by code review against
    // packages/auth's LanguageDropdown, which uses the identical two-step
    // sync this widget mirrors.
    await pumpOnboarding(tester, const GetStartedPage());

    expect(find.text('🇬🇧'), findsOneWidget);

    await tester.tap(find.text('🇬🇧'));
    await tester.pumpAndSettle();

    expect(find.text('🇬🇧  English'), findsOneWidget);
    expect(find.text('🇦🇪  العربية'), findsOneWidget);
  });

  testWidgets(
    'tapping UAE PASS / Google / Phone does not throw (no backend yet)',
    (tester) async {
      await pumpOnboarding(tester, const GetStartedPage());

      await tester.tap(find.text('onboarding.continue_uae_pass'));
      await tester.tap(find.text('onboarding.continue_google'));
      await tester.tap(find.text('onboarding.continue_phone'));
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tapping "Continue with Email" navigates to the email screen', (
    tester,
  ) async {
    await pumpOnboardingRouter(tester, _buildRouter());

    await tester.tap(find.text('onboarding.continue_email'));
    await tester.pumpAndSettle();

    expect(find.byType(ContinueWithEmailPage), findsOneWidget);
  });

  testWidgets('renders correctly under RTL', (tester) async {
    await pumpOnboarding(
      tester,
      const Directionality(
        textDirection: TextDirection.rtl,
        child: GetStartedPage(),
      ),
    );

    expect(find.text('onboarding.get_started_title'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
