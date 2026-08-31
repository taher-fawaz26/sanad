// No EasyLocalization bootstrap — see oauth_test_harness.dart. This card has
// no localization calls of its own (callers pass already-resolved strings),
// so no raw-key concern here.

import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/oauth/uae_pass_details_card.dart';

import 'oauth_test_harness.dart';

List<UaePassDetailRowData> _rows({
  UaePassDetailRowStatus first = UaePassDetailRowStatus.loading,
  UaePassDetailRowStatus second = UaePassDetailRowStatus.loading,
}) => [
  UaePassDetailRowData(
    iconAsset: AppSvgs.registrationProfile,
    label: 'Full name',
    value: 'Mohamed Shahat',
    status: first,
  ),
  UaePassDetailRowData(
    iconAsset: AppSvgs.uaePassVerifiedIdentity,
    label: 'Verified identity',
    value: 'Emirates ID • Verified by UAE PASS',
    status: second,
  ),
];

void main() {
  testWidgets('loading rows show no checkmark', (tester) async {
    await pumpOAuth(
      tester,
      Scaffold(
        body: UaePassDetailsCard(title: 'Collecting…', rows: _rows()),
      ),
    );

    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Mohamed Shahat'), findsOneWidget);
    expect(find.byType(AppVerifiedBadge), findsNothing);
  });

  testWidgets('completed rows show a checkmark badge', (tester) async {
    await pumpOAuth(
      tester,
      Scaffold(
        body: UaePassDetailsCard(
          title: 'Your Details',
          rows: _rows(
            first: UaePassDetailRowStatus.completed,
            second: UaePassDetailRowStatus.completed,
          ),
        ),
      ),
    );

    expect(find.byType(AppVerifiedBadge), findsNWidgets(2));
  });

  testWidgets('a divider separates rows but does not trail the last one', (
    tester,
  ) async {
    await pumpOAuth(
      tester,
      Scaffold(
        body: UaePassDetailsCard(title: 'Your Details', rows: _rows()),
      ),
    );

    // 2 rows → exactly 1 divider between them.
    expect(find.byType(AppDivider), findsOneWidget);
  });

  testWidgets('renders correctly under RTL', (tester) async {
    await pumpOAuth(
      tester,
      Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: UaePassDetailsCard(title: 'بياناتك', rows: _rows()),
        ),
      ),
    );

    expect(find.text('بياناتك'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders long values without throwing', (tester) async {
    await pumpOAuth(
      tester,
      const Scaffold(
        body: UaePassDetailsCard(
          title: 'Your Details',
          rows: [
            UaePassDetailRowData(
              iconAsset: AppSvgs.uaePassVerifiedIdentity,
              label: 'Verified identity',
              value:
                  'Emirates ID • Verified by UAE PASS • Additional issuing '
                  'authority detail that makes this value unusually long',
              status: UaePassDetailRowStatus.completed,
            ),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders under a large text scale without throwing', (
    tester,
  ) async {
    await pumpOAuth(
      tester,
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Scaffold(
          body: UaePassDetailsCard(title: 'Your Details', rows: _rows()),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
