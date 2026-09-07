// No EasyLocalization bootstrap — `.tr()` falls back to the raw key, so
// assertions match on raw i18n keys (see oauth_test_harness.dart /
// auth_page_test.dart for the same convention).
//
// Exercises the complete client authentication UI flow end to end against a
// mocked backend (see client_auth_test_locator.dart):
//   OAuth -> Email/Phone -> request-otp -> OTP -> verify -> Enter Name ->
//   clients/me -> Get Notified
// mirroring client_router.dart's actual route registration.
//
// Uses bounded `tester.pump()` calls around the OTP screen (never
// pumpAndSettle()) because of its indefinitely-blinking caret — see
// oauth_otp_page_test.dart's own header comment for the same rule.

import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_client/src/features/account_setup/account_setup_cubit.dart';
import 'package:sanad_client/src/features/account_setup/account_setup_routes.dart';
import 'package:sanad_client/src/features/account_setup/enter_name_page.dart';
import 'package:sanad_client/src/features/account_setup/get_notified_page.dart';
import 'package:sanad_client/src/features/oauth/oauth_email_page.dart';
import 'package:sanad_client/src/features/oauth/oauth_otp_page.dart';
import 'package:sanad_client/src/features/oauth/oauth_otp_route_args.dart';
import 'package:sanad_client/src/features/oauth/oauth_phone_page.dart';
import 'package:sanad_client/src/features/oauth/oauth_routes.dart';
import 'package:sanad_client/src/features/oauth/oauth_screen.dart';
import 'package:sanad_client/src/features/oauth/oauth_uae_pass_page.dart';
import 'package:sanad_client/src/routing/client_routes.dart';

import '../../support/client_auth_test_locator.dart';
import '../oauth/oauth_test_harness.dart';

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
      path: OAuthRoutes.phone,
      builder: (context, state) => const OAuthPhonePage(),
    ),
    GoRoute(
      path: OAuthRoutes.uaePass,
      builder: (context, state) => const OAuthUaePassPage(),
    ),
    GoRoute(
      path: OAuthRoutes.otp,
      redirect: (context, state) =>
          state.extra is OAuthOtpRouteArgs ? null : OAuthRoutes.screen,
      // Mirror production: never force-unwrap the imperative `extra` in the
      // builder (a background rebuild can drop it — see client_router.dart).
      builder: (context, state) {
        final args = state.extra;
        if (args is! OAuthOtpRouteArgs) return const SizedBox.shrink();
        return buildOAuthOtpRoutePage(context, args);
      },
    ),
    ShellRoute(
      builder: (context, state, child) => BlocProvider(
        create: (_) => AccountSetupCubit(
          updateProfile: sl<UpdateClientProfileUseCase>(),
          sessionManager: sl<SessionManager>(),
        ),
        child: child,
      ),
      routes: [
        GoRoute(
          path: AccountSetupRoutes.enterName,
          builder: (context, state) => const EnterNamePage(),
        ),
        GoRoute(
          path: AccountSetupRoutes.getNotified,
          builder: (context, state) => const GetNotifiedPage(),
        ),
      ],
    ),
    GoRoute(
      path: ClientRoutes.home,
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('home'))),
    ),
  ],
);

Future<void> _pumpRouter(WidgetTester tester) =>
    pumpOAuthRouter(tester, _buildRouter());

/// Taps Next on Email/Phone and settles the request-otp dispatch + the push
/// to the OTP screen.
Future<void> _tapNextToOtp(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(AppButton, 'oauth.next'));
  await tester.pump(); // request-otp resolves + push starts
  await tester.pump(const Duration(milliseconds: 350)); // push transition
  await tester.pump(const Duration(milliseconds: 50)); // cooldown probe
}

/// Types + submits a 6-digit code and settles verify → session → routing.
/// Bounded pumps throughout, matching the OTP field's indefinite caret.
Future<void> _completeOtp(WidgetTester tester) async {
  await tester.enterText(find.byType(EditableText).first, '123456');
  await tester.pump(); // enable the Next button
  await tester.tap(find.widgetWithText(AppButton, 'oauth.next'));
  await tester.pump(); // verify resolves
  await tester.pump(const Duration(milliseconds: 50)); // completeActiveLogin
  await tester.pump(); // onResult → push
  await tester.pump(const Duration(milliseconds: 350)); // push transition
}

void main() {
  setUpAll(registerClientAuthFallbacks);
  // First-time client by default (ACTIVE, name null) → Enter Name.
  setUp(
    () => registerClientAuthMocks(verifyResult: activeVerifyResult(name: null)),
  );
  tearDown(unregisterClientAuthMocks);

  testWidgets('OAuth -> Email -> OTP -> Enter Name -> Get Notified', (
    tester,
  ) async {
    await _pumpRouter(tester);

    await tester.tap(find.text('oauth.continue_email'));
    await tester.pumpAndSettle();
    expect(find.byType(OAuthEmailPage), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'user@example.com');
    await tester.pump();
    await _tapNextToOtp(tester);
    expect(find.byType(OAuthOtpPage), findsOneWidget);

    await _completeOtp(tester);
    expect(find.byType(EnterNamePage), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Mohamed Shahat');
    await tester.pump();
    await tester.tap(find.widgetWithText(AppButton, 'common.next'));
    await tester.pumpAndSettle();

    expect(find.byType(GetNotifiedPage), findsOneWidget);
  });

  testWidgets('OAuth -> Phone -> OTP -> Enter Name -> Get Notified', (
    tester,
  ) async {
    await _pumpRouter(tester);

    await tester.tap(find.text('oauth.continue_phone'));
    await tester.pumpAndSettle();
    expect(find.byType(OAuthPhonePage), findsOneWidget);

    await tester.enterText(find.byType(TextField), '501234567');
    await tester.pump();
    await _tapNextToOtp(tester);
    expect(find.byType(OAuthOtpPage), findsOneWidget);

    await _completeOtp(tester);
    expect(find.byType(EnterNamePage), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Mohamed Shahat');
    await tester.pump();
    await tester.tap(find.widgetWithText(AppButton, 'common.next'));
    await tester.pumpAndSettle();

    expect(find.byType(GetNotifiedPage), findsOneWidget);
  });

  testWidgets('returning client (name set) skips Enter Name → Home', (
    tester,
  ) async {
    // Override the default first-time result with a returning client.
    unregisterClientAuthMocks();
    registerClientAuthMocks(verifyResult: activeVerifyResult(name: 'Mohamed'));

    await _pumpRouter(tester);

    await tester.tap(find.text('oauth.continue_email'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'user@example.com');
    await tester.pump();
    await _tapNextToOtp(tester);
    expect(find.byType(OAuthOtpPage), findsOneWidget);

    await _completeOtp(tester);

    expect(find.byType(EnterNamePage), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('Google does not enter the OTP/account-setup flow', (
    tester,
  ) async {
    await _pumpRouter(tester);

    expect(find.text('oauth.continue_google'), findsOneWidget);
    expect(find.byType(OAuthOtpPage), findsNothing);
    expect(find.byType(EnterNamePage), findsNothing);
  });

  testWidgets('UAE PASS does not enter the OTP/account-setup flow', (
    tester,
  ) async {
    await _pumpRouter(tester);

    await tester.tap(find.text('oauth.continue_uae_pass'));
    await tester.pumpAndSettle();

    expect(find.byType(OAuthUaePassPage), findsOneWidget);
    expect(find.byType(OAuthOtpPage), findsNothing);
    expect(find.byType(EnterNamePage), findsNothing);
  });

  testWidgets('back navigation: OTP -> Email, never straight to OAuth', (
    tester,
  ) async {
    await _pumpRouter(tester);

    await tester.tap(find.text('oauth.continue_email'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'user@example.com');
    await tester.pump();
    await _tapNextToOtp(tester);
    expect(find.byType(OAuthOtpPage), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(OAuthOtpPage), findsNothing);
    expect(find.byType(OAuthEmailPage), findsOneWidget);
    expect(find.byType(OAuthScreen), findsNothing);
  });

  testWidgets(
    'Enter Name replaces the pre-auth stack — no back to OTP',
    (tester) async {
      await _pumpRouter(tester);

      await tester.tap(find.text('oauth.continue_email'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'user@example.com');
      await tester.pump();
      await _tapNextToOtp(tester);
      await _completeOtp(tester);
      expect(find.byType(EnterNamePage), findsOneWidget);

      // The session is authenticated now, so the OTP route was *replaced*
      // (via `go`), not layered under Enter Name — the pre-auth stack that
      // used to linger here is what a background refresh rebuilt and crashed
      // on. There is deliberately no back affordance, and OTP is gone.
      expect(find.byIcon(Icons.chevron_left), findsNothing);
      expect(find.byType(OAuthOtpPage), findsNothing);
    },
  );

  testWidgets('back navigation: Get Notified -> Enter Name', (tester) async {
    await _pumpRouter(tester);

    await tester.tap(find.text('oauth.continue_email'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'user@example.com');
    await tester.pump();
    await _tapNextToOtp(tester);
    await _completeOtp(tester);
    await tester.enterText(find.byType(TextField), 'Mohamed Shahat');
    await tester.pump();
    await tester.tap(find.widgetWithText(AppButton, 'common.next'));
    await tester.pumpAndSettle();
    expect(find.byType(GetNotifiedPage), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.byType(GetNotifiedPage), findsNothing);
    expect(find.byType(EnterNamePage), findsOneWidget);
  });
}
