import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/ai_transport_banner.dart';
import 'package:testing/testing.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required bool isOffline,
    required bool hasUndeliveredMessage,
  }) {
    return pumpDsWidget(
      tester,
      Scaffold(
        body: AiTransportBanner(
          isOffline: isOffline,
          hasUndeliveredMessage: hasUndeliveredMessage,
        ),
      ),
    );
  }

  group('AiTransportBanner', () {
    testWidgets('renders nothing when neither condition holds', (
      tester,
    ) async {
      await pump(tester, isOffline: false, hasUndeliveredMessage: false);
      await tester.pumpAndSettle();

      expect(find.text('ai_chat.offline_banner'), findsNothing);
      expect(find.text('ai_chat.send_failed_banner'), findsNothing);
    });

    testWidgets('offline wins over a send failure', (tester) async {
      await pump(tester, isOffline: true, hasUndeliveredMessage: true);
      await tester.pumpAndSettle();

      expect(find.text('ai_chat.offline_banner'), findsOneWidget);
      expect(find.text('ai_chat.send_failed_banner'), findsNothing);
    });

    testWidgets(
      'appearing and disappearing cross-fades instead of snapping',
      (tester) async {
        await pump(tester, isOffline: false, hasUndeliveredMessage: false);
        await tester.pumpAndSettle();
        expect(find.text('ai_chat.send_failed_banner'), findsNothing);

        await pump(tester, isOffline: false, hasUndeliveredMessage: true);
        // Mid cross-fade: the incoming banner is already in the tree (an
        // AnimatedSwitcher/state transition builds both briefly) rather than
        // appearing on the very next frame with no transition at all.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('ai_chat.send_failed_banner'), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.text('ai_chat.send_failed_banner'), findsOneWidget);

        await pump(tester, isOffline: false, hasUndeliveredMessage: false);
        await tester.pumpAndSettle();
        expect(find.text('ai_chat.send_failed_banner'), findsNothing);
      },
    );

    testWidgets('switching between offline and failed swaps the message', (
      tester,
    ) async {
      await pump(tester, isOffline: true, hasUndeliveredMessage: false);
      await tester.pumpAndSettle();
      expect(find.text('ai_chat.offline_banner'), findsOneWidget);

      await pump(tester, isOffline: false, hasUndeliveredMessage: true);
      await tester.pumpAndSettle();
      expect(find.text('ai_chat.send_failed_banner'), findsOneWidget);
      expect(find.text('ai_chat.offline_banner'), findsNothing);
    });
  });
}
