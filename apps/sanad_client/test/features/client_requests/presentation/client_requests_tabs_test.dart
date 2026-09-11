import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/client_requests_tab.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/widgets/client_requests_tabs.dart';
import 'package:testing/testing.dart';

/// Focused on the pill's motion, not layout (covered in
/// `client_requests_page_test.dart`).
void main() {
  Future<void> pump(
    WidgetTester tester, {
    ClientRequestsTab selected = ClientRequestsTab.active,
  }) {
    return pumpDsWidget(
      tester,
      ClientRequestsTabs(selected: selected, onSelected: (_) {}),
    );
  }

  BoxDecoration decorationOf(WidgetTester tester, String label) =>
      tester
              .widget<Ink>(
                find.ancestor(of: find.text(label), matching: find.byType(Ink)),
              )
              .decoration!
          as BoxDecoration;

  group('ClientRequestsTabs', () {
    testWidgets('a selected-state change animates the fill rather than '
        'snapping to it', (tester) async {
      await pump(tester);
      final unselectedColor = decorationOf(
        tester,
        'client_requests.tab_scheduled',
      ).color;

      await pump(tester, selected: ClientRequestsTab.scheduled);
      // Immediately after the rebuild, still mid-transition.
      await tester.pump(const Duration(milliseconds: 40));
      final midColor = decorationOf(
        tester,
        'client_requests.tab_scheduled',
      ).color;
      expect(midColor, isNot(unselectedColor));

      await tester.pumpAndSettle();
      final settledColor = decorationOf(
        tester,
        'client_requests.tab_scheduled',
      ).color;
      expect(settledColor, isNot(unselectedColor));
      expect(midColor, isNot(settledColor));
    });

    testWidgets('tapping still switches tabs while a previous transition is '
        'in flight', (tester) async {
      ClientRequestsTab? selectedTab;
      await pumpDsWidget(
        tester,
        StatefulBuilder(
          builder: (context, setState) => ClientRequestsTabs(
            selected: ClientRequestsTab.active,
            onSelected: (tab) => selectedTab = tab,
          ),
        ),
      );

      await tester.tap(find.text('client_requests.tab_cancelled'));
      await tester.pump(const Duration(milliseconds: 10));
      expect(selectedTab, ClientRequestsTab.cancelled);

      await tester.pumpAndSettle();
    });
  });
}
