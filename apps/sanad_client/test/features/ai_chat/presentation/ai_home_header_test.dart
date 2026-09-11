import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/ui/background/client_ambient_background.dart';
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
/// `ClientAmbientBackground` rather than a bare `Scaffold` is the point — glass over a
/// flat colour proves nothing.
void main() {
  Future<void> pumpHeader(
    WidgetTester tester, {
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
    AiHomeDestination selected = AiHomeDestination.sanad,
    // Mirrors the shell: History exists only in a debug build (A-10).
    bool showHistory = true,
  }) => pumpDsWidget(
    tester,
    Directionality(
      textDirection: direction,
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: ClientAmbientBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: AiHomeHeader(
                selected: selected,
                onSelected: (_) {},
                onProfileTap: () {},
                onHistoryTap: showHistory ? () {} : null,
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

  testWidgets('the pill and History are both glass', (tester) async {
    // Peer surfaces, one filter each — never one nested in another, which
    // would cost a second full pass for a panel with nothing new to blur.
    // Two, not three: the notifications bell moved to Profile for this phase.
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

  // Regression for A-10: the History control was rendered unconditionally
  // while its `/dev` route is registered only under `!kReleaseMode`, so a
  // release build would have shown a button that navigates nowhere.
  testWidgets('History disappears when the build has no History route', (
    tester,
  ) async {
    await pumpHeader(tester, showHistory: false);

    expect(tester.takeException(), isNull);
    // The pill only.
    expect(find.byType(ClientGlassSurface), findsNWidgets(1));
  });

  // The bell moved out of the header for this phase — Figma's
  // `header-actions` (`8385:4371`) is one control, and the inbox is reached
  // from Profile instead. This guards against it drifting back in without a
  // decision: two entry points to one inbox is the bug this replaced.
  testWidgets('the header carries no notifications bell', (tester) async {
    await pumpHeader(tester);

    expect(find.byType(AppNotificationIcon), findsNothing);
  });

  // Regression: the header overflowed once the notifications bell joined the
  // trailing controls (C-09). The pill's selected label is capped but was not
  // *compressible*, so a longer label pushed the pill past its slot. The
  // existing overflow test only pumped the default `sanad` destination, whose
  // label is the shortest — so it never saw it.
  group('the header fits every destination', () {
    for (final destination in AiHomeDestination.values) {
      testWidgets('no overflow with ${destination.name} selected', (
        tester,
      ) async {
        // The emulator's real width: 1080px at 3x = 360dp, the narrowest
        // mainstream size and the one this actually overflowed at.
        tester.view
          ..physicalSize = const Size(1080, 2400)
          ..devicePixelRatio = 3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await pumpHeader(tester, selected: destination);

        expect(tester.takeException(), isNull);
      });
    }
  });
}
