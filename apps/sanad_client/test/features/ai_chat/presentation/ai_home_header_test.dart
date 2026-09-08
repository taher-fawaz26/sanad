import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/home/ai_chat_background.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/home/ai_home_header.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/home/ai_home_nav_pill.dart';
import 'package:sanad_client/src/ui/glass/client_glass_surface.dart';
import 'package:testing/testing.dart';

/// The Home shell's persistent top row, over the background it actually sits
/// on.
///
/// The header is the first surface the glass treatment was applied to, and it
/// is the one with the least room: three controls, a mirrored layout, and a
/// label that grows with the user's text scale. Rendering it over the real
/// `AiChatBackground` rather than a bare `Scaffold` is the point — glass over a
/// flat colour proves nothing.
void main() {
  Future<void> pumpHeader(
    WidgetTester tester, {
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
    AiHomeDestination selected = AiHomeDestination.sanad,
  }) => pumpDsWidget(
    tester,
    Directionality(
      textDirection: direction,
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: AiChatBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: AiHomeHeader(
                selected: selected,
                onSelected: (_) {},
                onProfileTap: () {},
                onHistoryTap: () {},
              ),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('it renders over the page wash without overflowing', (
    tester,
  ) async {
    await pumpHeader(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(AiHomeNavPill), findsOneWidget);
    expect(find.bySemanticsLabel('ai_chat.nav_history'), findsOneWidget);
    expect(find.bySemanticsLabel('ai_chat.profile'), findsOneWidget);
  });

  testWidgets('the pill and the History button are both glass', (
    tester,
  ) async {
    // Two peer surfaces, one filter each — never one nested in the other, which
    // would cost a second full pass for a panel with nothing new to blur.
    await pumpHeader(tester);

    expect(find.byType(ClientGlassSurface), findsNWidgets(2));
    expect(find.byType(BackdropFilter), findsNWidgets(2));
  });

  testWidgets('the avatar stays opaque', (tester) async {
    // Three points of ring around an opaque photograph is not worth a blur
    // pass. If this becomes glass, it should be a decision, not a drift.
    await pumpHeader(tester);

    final glassAroundAvatar = find.ancestor(
      of: find.bySemanticsLabel('ai_chat.profile'),
      matching: find.byType(ClientGlassSurface),
    );
    expect(glassAroundAvatar, findsNothing);
  });

  testWidgets('it survives a mirrored layout', (tester) async {
    await pumpHeader(tester, direction: TextDirection.rtl);

    expect(tester.takeException(), isNull);
    expect(find.byType(ClientGlassSurface), findsNWidgets(2));
  });

  testWidgets('it survives a large accessibility text size', (tester) async {
    // The pill's label is capped and ellipsized for exactly this: at a large
    // scale a raw key — or a long translation — can demand more width than the
    // row has, and the header must give it back rather than overflow.
    await pumpHeader(tester, textScale: 2, selected: AiHomeDestination.myLife);

    expect(tester.takeException(), isNull);
  });
}
