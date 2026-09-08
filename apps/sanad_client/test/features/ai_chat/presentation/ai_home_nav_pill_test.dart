import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/home/ai_home_nav_pill.dart';
import 'package:sanad_client/src/ui/glass/client_glass_surface.dart';
import 'package:testing/testing.dart';

/// The three-segment Home nav pill.
///
/// EasyLocalization is deliberately not bootstrapped — this repo's
/// convention — so `.tr()` falls back to the raw key and assertions read
/// against keys.
void main() {
  // Matches `AiHomeHeader`'s real usage: the pill sits inside an `Expanded`
  // in a `Row`, which is what bounds its width. Pumped bare in a `Scaffold`,
  // the outer `Row(mainAxisSize: min)` has nothing to size itself against and
  // overflows — a test-harness mismatch, not a real layout bug, since
  // production always provides that ancestor.
  Future<void> pumpPill(
    WidgetTester tester, {
    required AiHomeDestination selected,
    required ValueChanged<AiHomeDestination> onSelected,
  }) => pumpDsWidget(
    tester,
    Scaffold(
      body: Row(
        children: [
          Expanded(
            child: AiHomeNavPill(selected: selected, onSelected: onSelected),
          ),
        ],
      ),
    ),
  );

  testWidgets('the active segment shows its label, the others do not', (
    tester,
  ) async {
    await pumpPill(
      tester,
      selected: AiHomeDestination.sanad,
      onSelected: (_) {},
    );

    expect(find.text('ai_chat.nav_sanad'), findsOneWidget);
    expect(find.text('ai_chat.nav_requests'), findsNothing);
    expect(find.text('ai_chat.nav_my_life'), findsNothing);
  });

  testWidgets('every segment is reachable regardless of which is active', (
    tester,
  ) async {
    await pumpPill(
      tester,
      selected: AiHomeDestination.requests,
      onSelected: (_) {},
    );

    expect(find.text('ai_chat.nav_requests'), findsOneWidget);
    expect(find.bySemanticsLabel('ai_chat.nav_sanad'), findsOneWidget);
    expect(find.bySemanticsLabel('ai_chat.nav_my_life'), findsOneWidget);
  });

  testWidgets('tapping a collapsed segment reports it, not the active one', (
    tester,
  ) async {
    AiHomeDestination? tapped;
    await pumpPill(
      tester,
      selected: AiHomeDestination.sanad,
      onSelected: (destination) => tapped = destination,
    );

    await tester.tap(find.bySemanticsLabel('ai_chat.nav_my_life'));
    await tester.pump();

    expect(tapped, AiHomeDestination.myLife);
  });

  testWidgets('every destination is exposed to accessibility, expanded or '
      'not', (tester) async {
    // The collapsed segments hide their label visually but must not become
    // invisible to a screen reader — that would leave two of the three
    // destinations unreachable by name.
    await pumpPill(
      tester,
      selected: AiHomeDestination.myLife,
      onSelected: (_) {},
    );

    for (final key in [
      'ai_chat.nav_sanad',
      'ai_chat.nav_requests',
      'ai_chat.nav_my_life',
    ]) {
      expect(
        find.bySemanticsLabel(key),
        findsOneWidget,
        reason: '$key must have an accessible name',
      );
    }
  });

  testWidgets('the pill is glass, and blurs once', (tester) async {
    // It floats over the page's gradient — and, on the landing state, over a
    // drifting glow. A solid fill hid the thing that gives the AI surface its
    // identity; one filter is what keeps the fix affordable.
    await pumpPill(
      tester,
      selected: AiHomeDestination.sanad,
      onSelected: (_) {},
    );

    expect(find.byType(ClientGlassSurface), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('the active segment stays opaque', (tester) async {
    // Its label is the one piece of text on this control, so it does not get
    // the page showing through it — and being the only solid fill is also what
    // makes "which destination am I on" readable at a glance.
    await pumpPill(
      tester,
      selected: AiHomeDestination.requests,
      onSelected: (_) {},
    );

    final fills = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .map((c) => (c.decoration! as BoxDecoration).color)
        .whereType<Color>()
        .where((c) => c.a > 0)
        .toList();

    expect(fills, hasLength(1), reason: 'exactly one segment is filled');
    expect(fills.single.a, 1.0, reason: 'and that fill is fully opaque');
  });
}
