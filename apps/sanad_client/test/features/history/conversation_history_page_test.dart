import 'dart:async';

import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_client/src/features/ai_chat/src/routes/ai_chat_routes.dart';
import 'package:sanad_client/src/features/history/history_page.dart';
import 'package:sanad_client/src/features/history/src/data/mock_conversation_history_source.dart';
import 'package:sanad_client/src/features/history/src/domain/conversation_history_entry.dart';
import 'package:sanad_client/src/features/history/src/domain/conversation_history_source.dart';
import 'package:sanad_client/src/features/history/src/presentation/widgets/conversation_history_card.dart';
import 'package:sanad_client/src/features/history/src/presentation/widgets/conversation_history_search_field.dart';
import 'package:sanad_client/src/features/history/src/presentation/widgets/conversation_history_start_button.dart';
import 'package:testing/testing.dart';

/// Conversation History's two renderings, over a real router.
///
/// A router rather than a bare `pumpDsWidget`, because two of the screen's
/// three interactions *are* navigation — back, and "Start a Conversation" —
/// and asserting them against a stub route proves the real `context.pop()` /
/// `context.go()` calls reach the right place rather than merely that a
/// callback fired.
void main() {
  /// The mock's timestamps are relative, so anchoring them keeps
  /// "Today"/"Yesterday" deterministic regardless of when the suite runs.
  final anchor = DateTime(2026, 9, 8, 18);

  late GoRouter router;

  Future<void> pumpHistory(
    WidgetTester tester, {
    ConversationHistorySource? source,
    TextDirection direction = TextDirection.ltr,
    ValueChanged<ConversationHistoryEntry>? onSelected,
  }) async {
    router = GoRouter(
      initialLocation: _hostRoute,
      routes: [
        GoRoute(
          path: _hostRoute,
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('host'))),
        ),
        GoRoute(
          path: AiChatRoutes.chat,
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('chat'))),
        ),
        GoRoute(
          path: AiChatRoutes.history,
          builder: (context, state) => HistoryPage(
            source: source ?? MockConversationHistorySource(now: anchor),
            onConversationSelected: onSelected,
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: testDesignSize,
        minTextAdapt: true,
        builder: (context, child) => MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
          builder: (context, child) =>
              Directionality(textDirection: direction, child: child!),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Pushed, exactly as the Home header reaches it — so `context.pop()` has
    // somewhere to go.
    // Fire-and-forget: `push` completes only when the pushed route pops,
    // which is the whole point of it still being on screen here.
    unawaited(router.push(AiChatRoutes.history));
    await tester.pumpAndSettle();
  }

  group('with previous conversations', () {
    testWidgets('it lists the conversations with title, time and preview', (
      tester,
    ) async {
      await pumpHistory(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('history.title'), findsOneWidget);
      expect(find.byType(ConversationHistorySearchField), findsOneWidget);

      // Lazily built, so only what fits is present — the assertion is that
      // several rows render, not that all ten do.
      expect(
        find.byType(ConversationHistoryCard).evaluate().length,
        greaterThan(1),
      );

      // Figma's first card, in all three of its parts.
      expect(find.text('Emirates ID Renewal'), findsOneWidget);
      // Unlocalized, the caption resolves to its own template key — which
      // is the assertion: every card renders a timestamp, built from the
      // `{day} · {time}` template rather than concatenated in Dart. Which
      // day word it picks is covered by the formatter's own test.
      expect(
        find.text('history.day_time'),
        findsWidgets,
        reason: 'each card renders a timestamp caption',
      );
      expect(
        find.textContaining('REF-2024-4821'),
        findsOneWidget,
        reason: 'the preview text renders',
      );
    });

    testWidgets('the list scrolls to conversations below the fold', (
      tester,
    ) async {
      await pumpHistory(tester);

      // The mock's last entry is deliberately far enough down to be unbuilt
      // on first frame.
      expect(find.text('Health Insurance Card'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('Health Insurance Card'),
        400,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();

      expect(find.text('Health Insurance Card'), findsOneWidget);
    });

    testWidgets('a long title stays on one line and the preview caps at two', (
      tester,
    ) async {
      await pumpHistory(tester);

      await tester.scrollUntilVisible(
        find.text('Vehicle Registration Renewal and Insurance Transfer'),
        400,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();

      final title = tester.widget<Text>(
        find.text('Vehicle Registration Renewal and Insurance Transfer'),
      );
      expect(title.maxLines, 1);
      expect(title.overflow, TextOverflow.ellipsis);

      await tester.scrollUntilVisible(
        find.textContaining('The enrolment window'),
        400,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();

      final preview = tester.widget<Text>(
        find.textContaining('The enrolment window'),
      );
      expect(
        preview.maxLines,
        2,
        reason: 'Figma draws every card at two lines of preview',
      );
      expect(preview.overflow, TextOverflow.ellipsis);
    });

    testWidgets('tapping a conversation reaches the interaction boundary', (
      tester,
    ) async {
      final tapped = <String>[];
      await pumpHistory(tester, onSelected: (entry) => tapped.add(entry.id));

      await tester.tap(find.text('Emirates ID Renewal'));
      await tester.pump();

      expect(tapped, ['emirates-id-renewal']);
      // And nothing navigated: there is no route that opens a stored
      // conversation yet, and the card must not invent one.
      expect(
        router.state.uri.path,
        AiChatRoutes.history,
      );
    });

    testWidgets('back returns to where the screen was pushed from', (
      tester,
    ) async {
      await pumpHistory(tester);

      await tester.tap(find.bySemanticsLabel('history.back'));
      await tester.pumpAndSettle();

      expect(find.text('host'), findsOneWidget);
    });

    testWidgets('there is no call to action over a populated list', (
      tester,
    ) async {
      // Figma's populated frame has no bottom bar — the green wash runs to
      // the screen edge.
      await pumpHistory(tester);

      expect(find.byType(ConversationHistoryStartButton), findsNothing);
    });

    testWidgets('it survives a mirrored layout', (tester) async {
      await pumpHistory(tester, direction: TextDirection.rtl);

      expect(tester.takeException(), isNull);
      expect(find.byType(ConversationHistorySearchField), findsOneWidget);
      expect(
        find.byType(ConversationHistoryCard).evaluate().length,
        greaterThan(1),
      );
    });

    testWidgets('card content resolves its own direction, as Figma sets it', (
      tester,
    ) async {
      // Figma marks the title and preview `dir="auto"`. Conversation content
      // is not necessarily in the app's language, and inheriting the page's
      // RTL for an English paragraph throws its full stop to the visual left.
      await pumpHistory(tester, direction: TextDirection.rtl);

      expect(
        tester.widget<Text>(find.text('Emirates ID Renewal')).textDirection,
        TextDirection.ltr,
      );
      expect(
        tester.widget<Text>(find.textContaining('REF-2024-4821')).textDirection,
        TextDirection.ltr,
      );
      // The chrome still mirrors — only the content paragraphs opt out.
      final card = tester.getRect(find.byType(ConversationHistoryCard).first);
      final glyph = tester.getCenter(
        find.descendant(
          of: find.byType(ConversationHistoryCard).first,
          matching: find.byType(SvgPicture),
        ),
      );
      expect(
        glyph.dx,
        greaterThan(card.center.dx),
        reason: 'the Sanad sparkle leads, so RTL puts it on the right',
      );
    });

    testWidgets('it survives a large accessibility text size', (tester) async {
      await pumpHistory(tester);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('search', () {
    testWidgets('a query narrows the list to what matches', (tester) async {
      await pumpHistory(tester);

      await tester.enterText(find.byType(TextField), 'flight');
      await tester.pumpAndSettle();

      expect(find.text('Flight Tickets'), findsOneWidget);
      expect(find.text('Emirates ID Renewal'), findsNothing);
      expect(find.byType(ConversationHistoryCard), findsOneWidget);
    });

    testWidgets('a query nothing matches shows the no-results copy', (
      tester,
    ) async {
      await pumpHistory(tester);

      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pumpAndSettle();

      expect(find.byType(ConversationHistoryCard), findsNothing);
      expect(find.text('history.no_results_title'), findsOneWidget);
      expect(find.text('history.no_results_description'), findsOneWidget);
      // "Start a Conversation" is the answer to an empty history, not to a
      // query that found nothing.
      expect(find.byType(ConversationHistoryStartButton), findsNothing);
      // The box stays, so the query can be corrected rather than only
      // cleared.
      expect(find.byType(ConversationHistorySearchField), findsOneWidget);
    });

    testWidgets('clearing the query restores the whole list', (tester) async {
      await pumpHistory(tester);

      await tester.enterText(find.byType(TextField), 'flight');
      await tester.pumpAndSettle();
      expect(find.byType(ConversationHistoryCard), findsOneWidget);

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      expect(find.text('Emirates ID Renewal'), findsOneWidget);
      expect(
        find.byType(ConversationHistoryCard).evaluate().length,
        greaterThan(1),
      );
    });

    testWidgets('the search field survives a mirrored layout', (tester) async {
      await pumpHistory(tester, direction: TextDirection.rtl);

      await tester.enterText(find.byType(TextField), 'flight');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ConversationHistoryCard), findsOneWidget);
    });
  });

  group('without previous conversations', () {
    const emptySource = MockConversationHistorySource(
      fixture: ConversationHistoryFixture.empty,
    );

    testWidgets('it draws the empty state from Figma', (tester) async {
      await pumpHistory(tester, source: emptySource);

      expect(tester.takeException(), isNull);
      expect(find.text('history.title'), findsOneWidget);
      expect(find.text('history.empty_title'), findsOneWidget);
      expect(find.text('history.empty_description'), findsOneWidget);
      expect(find.byType(ConversationHistoryStartButton), findsOneWidget);
      expect(find.text('history.start_conversation'), findsOneWidget);
      expect(find.byType(ConversationHistoryCard), findsNothing);
    });

    testWidgets('the centre visual is the illustration asset from the design', (
      tester,
    ) async {
      // Named explicitly rather than counted: a substitute Material icon or a
      // hand-drawn approximation would still satisfy "something renders", and
      // the point of this assertion is that the *provided* export is what
      // ships.
      await pumpHistory(tester, source: emptySource);

      final loaders = tester
          .widgetList<SvgPicture>(find.byType(SvgPicture))
          .map((picture) => picture.bytesLoader)
          .whereType<SvgAssetLoader>()
          .map((loader) => loader.assetName);

      expect(loaders, contains(AppSvgs.aiChatHistoryEmptyChat));
    });

    testWidgets('the call to action carries the AI surface own green', (
      tester,
    ) async {
      // Figma's `#1A7E6B` (`main/700`), not `AppColors.primary`'s `#26A68C`
      // (`main/600`) — the reason this CTA is a client-local button at all.
      await pumpHistory(tester, source: emptySource);

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(ConversationHistoryStartButton),
          matching: find.byType(Material),
        ),
      );
      final palettes = AppTheme.light().extension<AppColors>()!.palettes;
      expect(material.color, palettes.main.shade700);
      expect(material.color, isNot(palettes.main.shade600));
      expect(
        tester.getSize(find.byType(ConversationHistoryStartButton)).height,
        moreOrLessEquals(responsiveDimension(48), epsilon: 0.5),
      );
    });

    testWidgets('there is no search box with nothing to search', (
      tester,
    ) async {
      // Figma's empty frame has no field, and a box that can only ever return
      // nothing is worse than no box.
      await pumpHistory(tester, source: emptySource);

      expect(find.byType(ConversationHistorySearchField), findsNothing);
    });

    testWidgets('Start a Conversation goes to the AI chat route', (
      tester,
    ) async {
      await pumpHistory(tester, source: emptySource);

      await tester.tap(find.byType(ConversationHistoryStartButton));
      await tester.pumpAndSettle();

      expect(find.text('chat'), findsOneWidget);
      expect(router.state.uri.path, AiChatRoutes.chat);
    });

    testWidgets('it survives a mirrored layout', (tester) async {
      await pumpHistory(
        tester,
        source: emptySource,
        direction: TextDirection.rtl,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('history.empty_title'), findsOneWidget);
      expect(find.byType(ConversationHistoryStartButton), findsOneWidget);
    });

    testWidgets('it scrolls rather than clipping at a large text size', (
      tester,
    ) async {
      // The illustration is 220dp before any copy: at a doubled text scale
      // the block is taller than the page, which is why it lives in a
      // scrollable rather than a bare `Center`.
      await pumpHistory(tester, source: emptySource);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ConversationHistoryStartButton), findsOneWidget);
    });
  });
}

/// Stands in for whichever AI Home branch pushed History.
const _hostRoute = '/dev/ai-chat/history-test-host';
