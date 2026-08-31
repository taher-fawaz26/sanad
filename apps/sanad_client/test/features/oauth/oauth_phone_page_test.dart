// No EasyLocalization bootstrap — `.tr()` falls back to the raw key, so
// assertions match on raw i18n keys (see oauth_test_harness.dart /
// auth_page_test.dart for the same convention).

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_client/src/features/oauth/oauth_otp_page.dart';
import 'package:sanad_client/src/features/oauth/oauth_otp_route_args.dart';
import 'package:sanad_client/src/features/oauth/oauth_phone_page.dart';
import 'package:sanad_client/src/features/oauth/oauth_routes.dart';
import 'package:sanad_client/src/features/oauth/oauth_screen.dart';

import '../../support/client_auth_test_locator.dart';
import 'oauth_test_harness.dart';

Finder _nextButtonFinder() => find.widgetWithText(AppButton, 'oauth.next');

GoRouter _buildRouter() => GoRouter(
  initialLocation: OAuthRoutes.screen,
  routes: [
    GoRoute(
      path: OAuthRoutes.screen,
      builder: (context, state) => const OAuthScreen(),
    ),
    GoRoute(
      path: OAuthRoutes.phone,
      builder: (context, state) => const OAuthPhonePage(),
    ),
    GoRoute(
      path: OAuthRoutes.otp,
      redirect: (context, state) =>
          state.extra is OAuthOtpRouteArgs ? null : OAuthRoutes.screen,
      builder: (context, state) =>
          buildOAuthOtpRoutePage(context, state.extra! as OAuthOtpRouteArgs),
    ),
  ],
);

Future<void> _pumpAtPhoneScreen(WidgetTester tester) async {
  // Starts at OAuthScreen and taps through to the phone screen, mirroring
  // the real app's navigation stack — OAuthPhonePage's back chevron calls
  // context.pop(), which needs a previous page to return to. Driven via a
  // real tap (not a raw router.push) to match the one navigation pattern
  // already verified stable in oauth_screen_test.dart.
  await pumpOAuthRouter(tester, _buildRouter());
  await tester.tap(find.text('oauth.continue_phone'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(registerClientAuthFallbacks);
  setUp(registerClientAuthMocks);
  tearDown(unregisterClientAuthMocks);

  testWidgets(
    'renders back button, icon, title/subtitle, UAE flag and phone field',
    (tester) async {
      await _pumpAtPhoneScreen(tester);

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.text('oauth.phone_title'), findsOneWidget);
      expect(find.text('oauth.phone_subtitle'), findsOneWidget);
      expect(find.text('oauth.phone_number_label'), findsOneWidget);
      expect(find.text('+971'), findsOneWidget);
      expect(_nextButtonFinder(), findsOneWidget);
    },
  );

  testWidgets('Next is disabled while the phone field is empty', (
    tester,
  ) async {
    await _pumpAtPhoneScreen(tester);

    final button = tester.widget<AppButton>(_nextButtonFinder());
    expect(button.onPressed, isNull);
  });

  testWidgets('Next stays disabled for a landline (non-mobile) number', (
    tester,
  ) async {
    await _pumpAtPhoneScreen(tester);

    // UaePhoneValidator.isMobile requires a leading 5 — a landline-shaped
    // number must not enable Next.
    await tester.enterText(find.byType(TextField), '212345678');
    await tester.pump();

    final button = tester.widget<AppButton>(_nextButtonFinder());
    expect(button.onPressed, isNull);
  });

  testWidgets('shows an inline error for an invalid phone number', (
    tester,
  ) async {
    await _pumpAtPhoneScreen(tester);

    await tester.enterText(find.byType(TextField), '212345678');
    // autovalidateMode: onUserInteraction — a second edit re-triggers
    // validation after the field has been touched once.
    await tester.enterText(find.byType(TextField), '212345679');
    await tester.pump();

    expect(find.text('validation.form.uae_phone_invalid'), findsOneWidget);
  });

  testWidgets('Next is enabled for a valid UAE mobile number', (
    tester,
  ) async {
    await _pumpAtPhoneScreen(tester);

    await tester.enterText(find.byType(TextField), '501234567');
    await tester.pump();

    final button = tester.widget<AppButton>(_nextButtonFinder());
    expect(button.onPressed, isNotNull);
    expect(find.text('validation.form.uae_phone_invalid'), findsNothing);
  });

  testWidgets('tapping back pops to the previous screen', (tester) async {
    await _pumpAtPhoneScreen(tester);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.byType(OAuthScreen), findsOneWidget);
    expect(find.byType(OAuthPhonePage), findsNothing);
  });

  group('navigation to the shared OTP screen', () {
    // The OTP field autofocuses and its caret blinks indefinitely once the
    // screen mounts, so every pump after tapping Next must be bounded —
    // never pumpAndSettle() — exactly as oauth_otp_page_test.dart documents.
    Future<void> pumpAfterTapNext(WidgetTester tester) async {
      await tester.tap(_nextButtonFinder());
      await tester.pump(); // starts the push transition
      await tester.pump(const Duration(milliseconds: 350)); // settles it
      await tester.pump(const Duration(milliseconds: 50)); // settles OtpStarted
    }

    testWidgets(
      'a valid mobile number navigates to the OTP screen with the entered '
      'number, normalized to E.164',
      (tester) async {
        await _pumpAtPhoneScreen(tester);

        await tester.enterText(find.byType(TextField), '501234567');
        await tester.pump();
        await pumpAfterTapNext(tester);

        expect(find.byType(OAuthOtpPage), findsOneWidget);
        expect(find.byType(OAuthPhonePage), findsNothing);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is RichText &&
                widget.text.toPlainText().contains('+971501234567'),
          ),
          findsOneWidget,
          reason: 'the entered (normalized) number must be displayed',
        );
      },
    );

    testWidgets('a landline (non-mobile) number does not navigate', (
      tester,
    ) async {
      await _pumpAtPhoneScreen(tester);

      await tester.enterText(find.byType(TextField), '212345678');
      await tester.pump();
      await tester.tap(_nextButtonFinder(), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(OAuthPhonePage), findsOneWidget);
      expect(find.byType(OAuthOtpPage), findsNothing);
    });

    testWidgets('an empty phone number does not navigate', (tester) async {
      await _pumpAtPhoneScreen(tester);

      await tester.tap(_nextButtonFinder(), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(OAuthPhonePage), findsOneWidget);
      expect(find.byType(OAuthOtpPage), findsNothing);
    });

    testWidgets(
      'back navigation unwinds OTP -> Phone -> OAuth, never straight to OAuth',
      (tester) async {
        await _pumpAtPhoneScreen(tester);

        await tester.enterText(find.byType(TextField), '501234567');
        await tester.pump();
        await pumpAfterTapNext(tester);
        expect(find.byType(OAuthOtpPage), findsOneWidget);

        await tester.tap(find.byIcon(Icons.chevron_left));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.byType(OAuthOtpPage), findsNothing);
        expect(find.byType(OAuthPhonePage), findsOneWidget);
        expect(find.byType(OAuthScreen), findsNothing);

        await tester.tap(find.byIcon(Icons.chevron_left));
        await tester.pumpAndSettle();

        expect(find.byType(OAuthPhonePage), findsNothing);
        expect(find.byType(OAuthScreen), findsOneWidget);
      },
    );
  });

  testWidgets('renders correctly under RTL', (tester) async {
    await pumpOAuth(
      tester,
      const Directionality(
        textDirection: TextDirection.rtl,
        child: OAuthPhonePage(),
      ),
    );

    expect(find.text('oauth.phone_title'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
