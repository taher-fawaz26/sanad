// No EasyLocalization bootstrap — `.tr()` falls back to the raw key, so
// assertions match on raw i18n keys (see oauth_test_harness.dart).

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_client/src/features/oauth/oauth_routes.dart';
import 'package:sanad_client/src/features/oauth/oauth_uae_pass_collecting_page.dart';
import 'package:sanad_client/src/features/oauth/oauth_uae_pass_success_page.dart';

import 'oauth_test_harness.dart';

Finder _continueButtonFinder() =>
    find.widgetWithText(AppButton, 'oauth.continue_to_sanad');

bool _isContinueEnabled(WidgetTester tester) =>
    tester.widget<AppButton>(_continueButtonFinder()).onPressed != null;

void main() {
  testWidgets(
    'renders back button, illustration, title, progress and details card',
    (tester) async {
      await pumpOAuth(tester, const OAuthUaePassCollectingPage());
      // Flushes the cubit's staged timers so none are left pending when the
      // test ends (see testing.md's repeating-timer/animation caution).
      await tester.pump(const Duration(milliseconds: 2300));

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.text('oauth.uae_pass_collecting_title'), findsOneWidget);
      expect(
        find.text('oauth.uae_pass_collecting_card_title'),
        findsOneWidget,
      );
      expect(find.byType(AppProgressBar), findsOneWidget);
      expect(
        find.text('oauth.uae_pass_detail_full_name_label'),
        findsOneWidget,
      );
      expect(
        find.text('oauth.uae_pass_detail_verified_identity_label'),
        findsOneWidget,
      );
      expect(
        find.text('oauth.uae_pass_detail_mobile_number_label'),
        findsOneWidget,
      );
      expect(find.text('Mohamed Shahat'), findsOneWidget);
    },
  );

  testWidgets(
    'continue is disabled while any row is still loading, and enables once '
    'all three complete',
    (tester) async {
      await pumpOAuth(tester, const OAuthUaePassCollectingPage());

      expect(_isContinueEnabled(tester), isFalse);

      // Full name completes (~600ms).
      await tester.pump(const Duration(milliseconds: 700));
      expect(_isContinueEnabled(tester), isFalse);

      // Verified identity completes (~1400ms).
      await tester.pump(const Duration(milliseconds: 800));
      expect(_isContinueEnabled(tester), isFalse);

      // Mobile number completes (~2200ms) — all three done now.
      await tester.pump(const Duration(milliseconds: 800));
      expect(_isContinueEnabled(tester), isTrue);
    },
  );

  testWidgets('tapping continue once enabled navigates to the success screen', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: OAuthRoutes.uaePassCollecting,
      routes: [
        GoRoute(
          path: OAuthRoutes.uaePassCollecting,
          builder: (context, state) => const OAuthUaePassCollectingPage(),
        ),
        GoRoute(
          path: OAuthRoutes.uaePassSuccess,
          builder: (context, state) => const OAuthUaePassSuccessPage(),
        ),
      ],
    );

    await pumpOAuthRouter(tester, router);
    await tester.pump(const Duration(milliseconds: 2300));

    await tester.tap(_continueButtonFinder());
    await tester.pumpAndSettle();

    expect(find.byType(OAuthUaePassSuccessPage), findsOneWidget);
  });

  testWidgets('renders correctly under RTL', (tester) async {
    await pumpOAuth(
      tester,
      const Directionality(
        textDirection: TextDirection.rtl,
        child: OAuthUaePassCollectingPage(),
      ),
    );
    // Flushes the cubit's staged timers — see the first test's comment.
    await tester.pump(const Duration(milliseconds: 2300));

    expect(find.text('oauth.uae_pass_collecting_title'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
