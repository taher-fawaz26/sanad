// No EasyLocalization bootstrap in this test harness — `.tr()` falls back
// to the raw key (see oauth_test_harness.dart / auth_page_test.dart for the
// same convention). Assertions match on raw i18n keys.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_client/src/features/oauth/oauth_email_page.dart';
import 'package:sanad_client/src/features/oauth/oauth_phone_page.dart';
import 'package:sanad_client/src/features/oauth/oauth_routes.dart';
import 'package:sanad_client/src/features/oauth/oauth_screen.dart';
import 'package:sanad_client/src/features/oauth/oauth_uae_pass_page.dart';

import '../../support/client_auth_test_locator.dart';
import 'oauth_test_harness.dart';

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
  ],
);

void main() {
  setUpAll(registerClientAuthFallbacks);
  setUp(registerClientAuthMocks);
  tearDown(unregisterClientAuthMocks);

  testWidgets('renders title, subtitle and all four sign-in actions', (
    tester,
  ) async {
    await pumpOAuth(tester, const OAuthScreen());

    expect(find.text('oauth.get_started_title'), findsOneWidget);
    expect(find.text('oauth.get_started_subtitle'), findsOneWidget);
    expect(find.text('oauth.continue_uae_pass'), findsOneWidget);
    expect(find.text('oauth.continue_email'), findsOneWidget);
    expect(find.text('oauth.continue_google'), findsOneWidget);
    expect(find.text('oauth.continue_phone'), findsOneWidget);
    // Text.rich has no `.data`, so find.text can't match a span directly —
    // check the composed RichText's plain-text content instead.
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('oauth.terms_link'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('divider renders the shared "or" copy in uppercase', (
    tester,
  ) async {
    await pumpOAuth(tester, const OAuthScreen());

    // The shared `common.or` key falls back to its raw form ("common.or")
    // under this test's no-bootstrap convention, so the uppercase transform
    // this screen applies is verified against that raw key instead of the
    // real "OR" copy.
    expect(find.text('COMMON.OR'), findsOneWidget);
  });

  testWidgets('language selector shows both language options', (
    tester,
  ) async {
    // Only opens the menu — doesn't select an option. Selecting calls
    // easy_localization's context.setLocale(), which needs a live
    // EasyLocalization ancestor; bootstrapping that hangs in this repo's
    // widget-test sandbox (see oauth_test_harness.dart), so the actual
    // locale-sync behavior is verified by code review against
    // packages/auth's LanguageDropdown, which uses the identical two-step
    // sync this widget mirrors.
    await pumpOAuth(tester, const OAuthScreen());

    expect(find.text('🇬🇧'), findsOneWidget);

    await tester.tap(find.text('🇬🇧'));
    await tester.pumpAndSettle();

    expect(find.text('🇬🇧  English'), findsOneWidget);
    expect(find.text('🇦🇪  العربية'), findsOneWidget);
  });

  testWidgets('tapping Google does not throw (no screen in this phase yet)', (
    tester,
  ) async {
    await pumpOAuth(tester, const OAuthScreen());

    await tester.tap(find.text('oauth.continue_google'));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping "Continue with Email" navigates to the email screen', (
    tester,
  ) async {
    await pumpOAuthRouter(tester, _buildRouter());

    await tester.tap(find.text('oauth.continue_email'));
    await tester.pumpAndSettle();

    expect(find.byType(OAuthEmailPage), findsOneWidget);
  });

  testWidgets('tapping "Phone" navigates to the phone screen', (
    tester,
  ) async {
    await pumpOAuthRouter(tester, _buildRouter());

    await tester.tap(find.text('oauth.continue_phone'));
    await tester.pumpAndSettle();

    expect(find.byType(OAuthPhonePage), findsOneWidget);
  });

  testWidgets(
    'tapping "Continue with UAE PASS" navigates to the UAE PASS screen',
    (tester) async {
      await pumpOAuthRouter(tester, _buildRouter());

      await tester.tap(find.text('oauth.continue_uae_pass'));
      await tester.pumpAndSettle();

      expect(find.byType(OAuthUaePassPage), findsOneWidget);
    },
  );

  testWidgets('renders correctly under RTL', (tester) async {
    await pumpOAuth(
      tester,
      const Directionality(
        textDirection: TextDirection.rtl,
        child: OAuthScreen(),
      ),
    );

    expect(find.text('oauth.get_started_title'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
