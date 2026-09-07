import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/history/history_page.dart';
import 'package:sanad_client/src/features/my_life/my_life_page.dart';
import 'package:sanad_client/src/features/profile/profile_page.dart';
import 'package:sanad_client/src/features/requests/requests_page.dart';
import 'package:testing/testing.dart';

/// The four structural-shell pages this task adds — Requests, My Life,
/// History and the upgraded Profile. None has real business logic yet, so
/// each test only asserts the page renders its copy without throwing, which
/// is exactly what "minimum structural shell" promises and no more.
void main() {
  testWidgets('RequestsPage renders its placeholder copy', (tester) async {
    await pumpDsWidget(tester, const RequestsPage());

    expect(find.text('requests.empty_title'), findsOneWidget);
    expect(find.text('requests.empty_description'), findsOneWidget);
  });

  testWidgets('MyLifePage renders its placeholder copy', (tester) async {
    await pumpDsWidget(tester, const MyLifePage());

    expect(find.text('my_life.empty_title'), findsOneWidget);
    expect(find.text('my_life.empty_description'), findsOneWidget);
  });

  testWidgets('HistoryPage renders its own back-navigable app bar', (
    tester,
  ) async {
    await pumpDsWidget(tester, const HistoryPage());

    expect(find.text('history.title'), findsOneWidget);
    expect(find.text('history.empty_title'), findsOneWidget);
    // Unlike the two shell branches above, this is a pushed page — it needs
    // its own way back, which a shell branch gets from the persistent header
    // instead. `AppNavBar` draws its own chevron rather than a Material
    // `BackButton`.
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
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
