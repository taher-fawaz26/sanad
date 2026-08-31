// No EasyLocalization bootstrap — `.tr()` falls back to the raw key, so
// assertions match on raw i18n keys (see oauth_test_harness.dart).

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/oauth/oauth_uae_pass_success_page.dart';
import 'package:sanad_client/src/features/oauth/uae_pass_collected_details.dart';

import 'oauth_test_harness.dart';

void main() {
  testWidgets(
    'renders success icon, title, progress, and all three completed rows',
    (tester) async {
      await pumpOAuth(tester, const OAuthUaePassSuccessPage());

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.text('oauth.uae_pass_success_title'), findsOneWidget);
      expect(find.text('oauth.uae_pass_success_card_title'), findsOneWidget);
      expect(find.byType(AppProgressBar), findsOneWidget);

      final progressBar = tester.widget<AppProgressBar>(
        find.byType(AppProgressBar),
      );
      expect(progressBar.value, 1);

      expect(
        find.text('oauth.uae_pass_detail_full_name_label'),
        findsOneWidget,
      );
      expect(find.text('Mohamed Shahat'), findsOneWidget);
      expect(
        find.text('oauth.uae_pass_detail_verified_identity_label'),
        findsOneWidget,
      );
      expect(
        find.text('Emirates ID • Verified by UAE PASS'),
        findsOneWidget,
      );
      expect(
        find.text('oauth.uae_pass_detail_mobile_number_label'),
        findsOneWidget,
      );
      expect(find.text('+971 5 • • • • • • 28'), findsOneWidget);

      // All three rows completed — three checkmarks, no loading indicator.
      expect(find.byType(AppVerifiedBadge), findsNWidgets(3));
    },
  );

  testWidgets('renders provided details instead of the placeholder', (
    tester,
  ) async {
    await pumpOAuth(
      tester,
      const OAuthUaePassSuccessPage(
        details: UaePassCollectedDetails(
          fullName: 'Sara Ahmed',
          verifiedIdentityLabel: 'Passport • Verified by UAE PASS',
          maskedMobileNumber: '+971 5 • • • • • • 99',
        ),
      ),
    );

    expect(find.text('Sara Ahmed'), findsOneWidget);
    expect(find.text('Mohamed Shahat'), findsNothing);
  });

  testWidgets('tapping continue to Sanad does not throw (no session yet)', (
    tester,
  ) async {
    await pumpOAuth(tester, const OAuthUaePassSuccessPage());

    await tester.tap(find.text('oauth.continue_to_sanad'));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders correctly under RTL', (tester) async {
    await pumpOAuth(
      tester,
      const Directionality(
        textDirection: TextDirection.rtl,
        child: OAuthUaePassSuccessPage(),
      ),
    );

    expect(find.text('oauth.uae_pass_success_title'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
