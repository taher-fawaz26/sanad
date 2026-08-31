// No EasyLocalization bootstrap — `.tr()` falls back to the raw key.
//
// Drives OAuthOtpPage through its real service-locator-backed verifier
// (`buildOAuthOtpRoutePage`) and asserts the server-driven routing after a
// verify: ACTIVE + name null → Enter Name, ACTIVE + name set → Home, and the
// non-ACTIVE statuses to their dedicated routes.
//
// Bounded `tester.pump()` calls only (never pumpAndSettle) — the OTP caret
// blinks indefinitely.

import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:otp/otp.dart';
import 'package:sanad_client/src/features/account_setup/account_setup_routes.dart';
import 'package:sanad_client/src/features/oauth/oauth_otp_page.dart';
import 'package:sanad_client/src/features/oauth/oauth_otp_route_args.dart';
import 'package:sanad_client/src/features/oauth/oauth_routes.dart';
import 'package:sanad_client/src/routing/client_routes.dart';

import '../../support/client_auth_test_locator.dart';

Widget _placeholder(String label) => Scaffold(body: Center(child: Text(label)));

GoRouter _router() => GoRouter(
  initialLocation: '/start',
  routes: [
    GoRoute(
      path: '/start',
      builder: (context, state) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.push(
              OAuthRoutes.otp,
              extra: const OAuthOtpRouteArgs(
                channel: OtpChannel.email,
                destination: 'user@example.com',
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
    GoRoute(
      path: OAuthRoutes.otp,
      builder: (context, state) =>
          buildOAuthOtpRoutePage(context, state.extra! as OAuthOtpRouteArgs),
    ),
    GoRoute(
      path: AccountSetupRoutes.enterName,
      builder: (context, state) => _placeholder('enter-name'),
    ),
    GoRoute(
      path: ClientRoutes.home,
      builder: (context, state) => _placeholder('home'),
    ),
    GoRoute(
      path: AuthRoutes.suspended,
      builder: (context, state) => _placeholder('suspended'),
    ),
    GoRoute(
      path: AuthRoutes.scheduledForDeletion,
      builder: (context, state) => _placeholder('scheduled'),
    ),
  ],
);

Future<void> _openOtpAndVerify(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1080, 2400));
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) =>
          MaterialApp.router(theme: AppTheme.light(), routerConfig: _router()),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));

  await tester.tap(find.text('open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump(const Duration(milliseconds: 50)); // cooldown probe

  await tester.enterText(find.byType(EditableText).first, '123456');
  await tester.pump(); // enable the Next button
  await tester.tap(find.widgetWithText(AppButton, 'oauth.next'));
  // Verify → completeActiveLogin (prime/GET me/save) → route.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  setUpAll(registerClientAuthFallbacks);
  tearDown(unregisterClientAuthMocks);

  testWidgets('ACTIVE + name null → Enter Name', (tester) async {
    registerClientAuthMocks(verifyResult: activeVerifyResult(name: null));

    await _openOtpAndVerify(tester);

    expect(find.text('enter-name'), findsOneWidget);
  });

  testWidgets('ACTIVE + name set → Home', (tester) async {
    registerClientAuthMocks(verifyResult: activeVerifyResult(name: 'Mohamed'));

    await _openOtpAndVerify(tester);

    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('SUSPENDED → suspended route', (tester) async {
    registerClientAuthMocks(
      verifyResult: const ClientVerifyResult(
        status: AuthAccountStatus.suspended,
      ),
    );

    await _openOtpAndVerify(tester);

    expect(find.text('suspended'), findsOneWidget);
  });

  testWidgets('SCHEDULED_FOR_DELETION → scheduled route', (tester) async {
    registerClientAuthMocks(
      verifyResult: const ClientVerifyResult(
        status: AuthAccountStatus.scheduledForDeletion,
      ),
    );

    await _openOtpAndVerify(tester);

    expect(find.text('scheduled'), findsOneWidget);
  });
}
