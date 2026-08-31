// No EasyLocalization bootstrap — `.tr()` falls back to the raw key, so
// assertions match on raw i18n keys (see oauth_test_harness.dart /
// auth_page_test.dart for the same convention).

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_client/src/features/oauth/oauth_email_page.dart';
import 'package:sanad_client/src/features/oauth/oauth_otp_page.dart';
import 'package:sanad_client/src/features/oauth/oauth_otp_route_args.dart';
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
      path: OAuthRoutes.email,
      builder: (context, state) => const OAuthEmailPage(),
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

Future<void> _pumpAtEmailScreen(WidgetTester tester) async {
  // Starts at OAuthScreen and taps through to the email screen, mirroring
  // the real app's navigation stack — OAuthEmailPage's back chevron calls
  // context.pop(), which needs a previous page to return to. Driven via a
  // real tap (not a raw router.push) to match the one navigation pattern
  // already verified stable in oauth_screen_test.dart / oauth_phone_page_test.dart
  // (a raw router.push() here left pumpAndSettle() hanging indefinitely).
  await pumpOAuthRouter(tester, _buildRouter());
  await tester.tap(find.text('oauth.continue_email'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(registerClientAuthFallbacks);
  setUp(registerClientAuthMocks);
  tearDown(unregisterClientAuthMocks);

  testWidgets('renders back button, icon, title/subtitle and email field', (
    tester,
  ) async {
    await _pumpAtEmailScreen(tester);

    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(find.text('oauth.email_title'), findsOneWidget);
    expect(find.text('oauth.email_subtitle'), findsOneWidget);
    expect(find.text('oauth.email_label'), findsOneWidget);
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

  testWidgets('shows an inline error for an invalid email', (tester) async {
    await _pumpAtEmailScreen(tester);

    await tester.enterText(find.byType(TextField), 'not-an-email');
    // autovalidateMode: onUserInteraction — a second edit re-triggers
    // validation after the field has been touched once.
    await tester.enterText(find.byType(TextField), 'not-an-email-2');
    await tester.pump();

    expect(find.text('auth.invalid_email'), findsOneWidget);
  });

  testWidgets('Next is enabled for a valid email', (tester) async {
    await _pumpAtEmailScreen(tester);

    await tester.enterText(find.byType(TextField), 'user@example.com');
    await tester.pump();

    final button = tester.widget<AppButton>(_nextButtonFinder());
    expect(button.onPressed, isNotNull);
    expect(find.text('auth.invalid_email'), findsNothing);
  });

  testWidgets('tapping back pops to the previous screen', (tester) async {
    await _pumpAtEmailScreen(tester);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.byType(OAuthScreen), findsOneWidget);
    expect(find.byType(OAuthEmailPage), findsNothing);
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
      'a valid email navigates to the OTP screen with the entered address',
      (tester) async {
        await _pumpAtEmailScreen(tester);

        await tester.enterText(find.byType(TextField), 'user@example.com');
        await tester.pump();
        await pumpAfterTapNext(tester);

        expect(find.byType(OAuthOtpPage), findsOneWidget);
        expect(find.byType(OAuthEmailPage), findsNothing);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is RichText &&
                widget.text.toPlainText().contains('user@example.com'),
          ),
          findsOneWidget,
          reason: 'the entered email, not a placeholder, must be displayed',
        );
      },
    );

    testWidgets('an invalid email does not navigate', (tester) async {
      await _pumpAtEmailScreen(tester);

      await tester.enterText(find.byType(TextField), 'not-an-email');
      await tester.pump();
      await tester.tap(_nextButtonFinder(), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(OAuthEmailPage), findsOneWidget);
      expect(find.byType(OAuthOtpPage), findsNothing);
    });

    testWidgets('an empty email does not navigate', (tester) async {
      await _pumpAtEmailScreen(tester);

      await tester.tap(_nextButtonFinder(), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(OAuthEmailPage), findsOneWidget);
      expect(find.byType(OAuthOtpPage), findsNothing);
    });

    testWidgets(
      'back navigation unwinds OTP -> Email -> OAuth, never straight to OAuth',
      (tester) async {
        await _pumpAtEmailScreen(tester);

        await tester.enterText(find.byType(TextField), 'user@example.com');
        await tester.pump();
        await pumpAfterTapNext(tester);
        expect(find.byType(OAuthOtpPage), findsOneWidget);

        await tester.tap(find.byIcon(Icons.chevron_left));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.byType(OAuthOtpPage), findsNothing);
        expect(find.byType(OAuthEmailPage), findsOneWidget);
        expect(find.byType(OAuthScreen), findsNothing);

        await tester.tap(find.byIcon(Icons.chevron_left));
        await tester.pumpAndSettle();

        expect(find.byType(OAuthEmailPage), findsNothing);
        expect(find.byType(OAuthScreen), findsOneWidget);
      },
    );
  });

  testWidgets('renders correctly under RTL', (tester) async {
    await pumpOAuth(
      tester,
      const Directionality(
        textDirection: TextDirection.rtl,
        child: OAuthEmailPage(),
      ),
    );

    expect(find.text('oauth.email_title'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
