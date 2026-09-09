import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/my_life/my_life_page.dart';
import 'package:sanad_client/src/features/profile/profile_page.dart';
import 'package:testing/testing.dart';

/// The structural-shell pages — My Life and the upgraded Profile. Neither has
/// real business logic yet, so each test only asserts the page renders its copy
/// without throwing, which is exactly what "minimum structural shell" promises
/// and no more.
///
/// Requests and History both used to be here. Both are built screens now, with
/// their own data and states, so their coverage lives in
/// `test/features/client_requests/` and `test/features/history/`.
void main() {
  testWidgets('MyLifePage renders its placeholder copy', (tester) async {
    await pumpDsWidget(tester, const MyLifePage());

    expect(find.text('my_life.empty_title'), findsOneWidget);
    expect(find.text('my_life.empty_description'), findsOneWidget);
  });

  testWidgets('ClientProfilePage renders its own back-navigable app bar', (
    tester,
  ) async {
    await pumpDsWidget(tester, const ClientProfilePage());

    expect(find.text('profile.title'), findsOneWidget);
    expect(find.text('profile.empty_title'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
  });
}
