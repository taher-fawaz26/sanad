import 'dart:async';
import 'dart:io';

import 'package:app_animations/app_animations.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_client/src/features/ai_chat/src/routes/ai_chat_routes.dart';
import 'package:sanad_client/src/features/history/history_page.dart';
import 'package:sanad_client/src/features/history/src/domain/conversation_history_entry.dart';
import 'package:sanad_client/src/features/history/src/domain/conversation_history_source.dart';
import 'package:sanad_client/src/features/history/src/presentation/widgets/conversation_history_card.dart';
import 'package:sanad_client/src/features/history/src/presentation/widgets/conversation_history_swipe_row.dart';
import 'package:testing/testing.dart';

/// Conversation History's swipe actions and the two dialogs they open —
/// Figma `actions` (`8487:31503`), `8516:32425`, `8516:32435`.
///
/// Localization is not bootstrapped (see `conversation_history_page_test` for
/// why), so `.tr()` answers with the key and the finders below look for keys.
/// That is deliberate here rather than merely tolerated: it means these tests
/// assert *which* key each surface uses, which is the half of the copy
/// contract a test can actually own.
///
/// The fixtures carry no relative timestamps and only two rows, so a swipe has
/// an unambiguous target and the whole list fits on screen.
class _TwoConversations implements ConversationHistorySource {
  const _TwoConversations();

  @override
  List<ConversationHistoryEntry> load() => [
    ConversationHistoryEntry(
      id: 'c1',
      title: 'Emirates ID Renewal',
      preview: 'Your renewal is being processed.',
      updatedAt: DateTime(2026, 9, 8, 18),
    ),
    ConversationHistoryEntry(
      id: 'c2',
      title: 'Home Cleaning',
      preview: 'Three providers have replied.',
      updatedAt: DateTime(2026, 9, 7, 11),
    ),
  ];
}

const _hostRoute = '/dev/ai-chat/history-swipe-test-host';

void main() {
  Future<void> pumpHistory(
    WidgetTester tester, {
    TextDirection direction = TextDirection.ltr,
    bool reduceMotion = false,
  }) async {
    // The emulator's real width: 1080px at 3x. The default 800x600 test
    // surface makes `ScreenUtil` scale a 360dp design up by ~2.2, which is
    // enough to overflow a dialog that fits comfortably on any real phone.
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: _hostRoute,
      routes: [
        GoRoute(
          path: _hostRoute,
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('host'))),
        ),
        GoRoute(
          path: AiChatRoutes.history,
          builder: (context, state) =>
              const HistoryPage(source: _TwoConversations()),
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
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: reduceMotion,
            ),
            child: Directionality(textDirection: direction, child: child!),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    unawaited(router.push(AiChatRoutes.history));
    await tester.pumpAndSettle();
  }

  Finder rowFor(String title) => find.ancestor(
    of: find.text(title),
    matching: find.byType(ConversationHistorySwipeRow),
  );

  Future<void> openActions(
    WidgetTester tester,
    String title, {
    TextDirection direction = TextDirection.ltr,
  }) async {
    final dx = direction == TextDirection.rtl ? 300.0 : -300.0;
    await tester.drag(find.text(title), Offset(dx, 0), warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  /// The revealed cells, found by runtime type rather than by importing
  /// `flutter_slidable`.
  ///
  /// The app deliberately does not depend on that package — `AppSwipeActions`
  /// is the only thing allowed to — and a test that imported it to measure a
  /// rectangle would be the first crack in that rule. The design system's own
  /// suite, where the import is legitimate, asserts the same geometry against
  /// the typed widget.
  Finder actionCells() => find.byWidgetPredicate(
    (widget) => widget.runtimeType.toString() == 'CustomSlidableAction',
  );

  List<Rect> cellRects(WidgetTester tester) => tester
      .widgetList(actionCells())
      .map((cell) => tester.getRect(find.byWidget(cell)))
      .toList();

  group('swipe actions', () {
    testWidgets('a swipe reveals Delete and Rename as one grouped strip', (
      tester,
    ) async {
      await pumpHistory(tester);
      expect(actionCells(), findsNothing);

      await openActions(tester, 'Emirates ID Renewal');

      expect(find.text('common.delete'), findsOneWidget);
      expect(find.text('history.rename'), findsOneWidget);

      final rects = cellRects(tester);
      expect(rects, hasLength(2));
      // No gap, equal cells, aligned tops and bottoms — the whole point of
      // the grouped style.
      expect(rects[0].right, closeTo(rects[1].left, 0.01));
      expect(rects[0].width, closeTo(rects[1].width, 0.01));
      expect(rects[0].height, closeTo(rects[1].height, 0.01));
      expect(rects[0].top, closeTo(rects[1].top, 0.01));
    });

    testWidgets('the strip is as tall as the card it is revealed behind', (
      tester,
    ) async {
      await pumpHistory(tester);
      await openActions(tester, 'Emirates ID Renewal');

      final card = tester.getRect(
        find.descendant(
          of: rowFor('Emirates ID Renewal'),
          matching: find.byType(ConversationHistoryCard),
        ),
      );
      final rects = cellRects(tester);

      expect(rects[0].height, closeTo(card.height, 0.01));
      expect(rects[0].top, closeTo(card.top, 0.01));
    });

    testWidgets('Delete leads the strip and keeps the destructive colour', (
      tester,
    ) async {
      await pumpHistory(tester);
      await openActions(tester, 'Emirates ID Renewal');

      expect(
        tester.getCenter(find.text('common.delete')).dx,
        lessThan(tester.getCenter(find.text('history.rename')).dx),
      );

      // The destructive token, read off the painted cell — the same colour
      // the confirmation dialog's CTA uses.
      final colors = AppTheme.light().extension<AppColors>()!;
      final fill = tester
          .widgetList<Material>(
            find.descendant(
              of: actionCells().first,
              matching: find.byType(Material),
            ),
          )
          .map((material) => material.color)
          .toList();
      expect(fill, contains(colors.error));
    });

    testWidgets('only one row keeps its actions open at a time', (
      tester,
    ) async {
      await pumpHistory(tester);

      await openActions(tester, 'Emirates ID Renewal');
      expect(actionCells(), findsNWidgets(2));

      await openActions(tester, 'Home Cleaning');
      // Two cells, not four: the group closed the first row when the second
      // opened.
      expect(actionCells(), findsNWidgets(2));
    });

    testWidgets('repeated open/close cycles accumulate no state', (
      tester,
    ) async {
      await pumpHistory(tester);

      Rect? firstGeometry;
      for (var cycle = 0; cycle < 3; cycle++) {
        await openActions(tester, 'Emirates ID Renewal');
        expect(actionCells(), findsNWidgets(2));

        final rects = cellRects(tester);
        firstGeometry ??= rects[0];
        expect(rects[0], firstGeometry);

        // Cancelling a dialog is the app's own close path: the pane closes
        // when the action is chosen, whatever the user then answers.
        await tester.tap(find.text('history.rename'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('common.cancel'));
        await tester.pumpAndSettle();

        expect(actionCells(), findsNothing);
        expect(tester.binding.hasScheduledFrame, isFalse);
      }

      expect(tester.takeException(), isNull);
    });

    testWidgets('mirrors under RTL', (tester) async {
      await pumpHistory(tester, direction: TextDirection.rtl);
      await openActions(
        tester,
        'Emirates ID Renewal',
        direction: TextDirection.rtl,
      );

      expect(find.text('common.delete'), findsOneWidget);
      expect(find.text('history.rename'), findsOneWidget);
      // Leading edge is the right-hand one, so Delete leads from the right.
      expect(
        tester.getCenter(find.text('common.delete')).dx,
        greaterThan(tester.getCenter(find.text('history.rename')).dx),
      );

      final rects = cellRects(tester);
      expect(rects[0].left, closeTo(rects[1].right, 0.01));
    });

    testWidgets('reveals the actions without motion under reduced motion', (
      tester,
    ) async {
      await pumpHistory(tester, reduceMotion: true);
      await openActions(tester, 'Emirates ID Renewal');

      expect(find.text('common.delete'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppSwipeActionReveal),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
    });
  });

  group('delete', () {
    testWidgets('opens the shared delete dialog', (tester) async {
      await pumpHistory(tester);
      await openActions(tester, 'Emirates ID Renewal');
      await tester.tap(find.text('common.delete'));
      await tester.pumpAndSettle();

      expect(find.byType(AppPopover), findsOneWidget);
      expect(find.text('history.delete_conversation_title'), findsOneWidget);
      expect(
        find.text('history.delete_conversation_description'),
        findsOneWidget,
      );
      expect(find.text('common.cancel'), findsOneWidget);
    });

    testWidgets('keeps the conversation when cancelled', (tester) async {
      await pumpHistory(tester);
      await openActions(tester, 'Emirates ID Renewal');
      await tester.tap(find.text('common.delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('common.cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AppPopover), findsNothing);
      expect(find.text('Emirates ID Renewal'), findsOneWidget);
      expect(find.byType(ConversationHistoryCard), findsNWidgets(2));
    });

    testWidgets('removes the conversation when confirmed', (tester) async {
      await pumpHistory(tester);
      await openActions(tester, 'Emirates ID Renewal');
      await tester.tap(find.text('common.delete'));
      await tester.pumpAndSettle();

      // The dialog's own destructive CTA, not the swipe cell behind it.
      await tester.tap(
        find.descendant(
          of: find.byType(AppPopover),
          matching: find.text('common.delete'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Emirates ID Renewal'), findsNothing);
      expect(find.text('Home Cleaning'), findsOneWidget);
      expect(find.byType(ConversationHistoryCard), findsOneWidget);
    });

    testWidgets('renders its CTA as destructive', (tester) async {
      await pumpHistory(tester);
      await openActions(tester, 'Emirates ID Renewal');
      await tester.tap(find.text('common.delete'));
      await tester.pumpAndSettle();

      final popover = tester.widget<AppPopover>(find.byType(AppPopover));
      expect(popover.primaryDestructive, isTrue);
      expect(popover.alignment, AppPopoverAlignment.start);
      expect(popover.secondaryOutlined, isTrue);
    });
  });

  group('rename', () {
    Future<void> openRename(WidgetTester tester) async {
      await openActions(tester, 'Emirates ID Renewal');
      await tester.tap(find.text('history.rename'));
      await tester.pumpAndSettle();
    }

    testWidgets('opens the shared rename dialog with its field', (
      tester,
    ) async {
      await pumpHistory(tester);
      await openRename(tester);

      expect(find.byType(AppPopover), findsOneWidget);
      expect(find.text('history.rename_conversation_title'), findsOneWidget);
      expect(
        find.text('history.rename_conversation_description'),
        findsOneWidget,
      );
      expect(
        find.text('history.rename_conversation_field_label'),
        findsOneWidget,
      );
      expect(find.byType(AppTextField), findsOneWidget);

      final popover = tester.widget<AppPopover>(find.byType(AppPopover));
      expect(popover.actions, AppPopoverActions.textInput);
      expect(popover.alignment, AppPopoverAlignment.start);
      expect(popover.textFieldHint, 'history.rename_conversation_field_hint');
    });

    testWidgets('pre-fills the field with the current title', (tester) async {
      await pumpHistory(tester);
      await openRename(tester);

      expect(find.text('Emirates ID Renewal'), findsWidgets);
      final popover = tester.widget<AppPopover>(find.byType(AppPopover));
      expect(popover.textFieldController?.text, 'Emirates ID Renewal');
    });

    testWidgets('leaves the title alone when cancelled', (tester) async {
      await pumpHistory(tester);
      await openRename(tester);

      await tester.enterText(find.byType(AppTextField), 'Renamed');
      await tester.tap(find.text('common.cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AppPopover), findsNothing);
      expect(find.text('Emirates ID Renewal'), findsOneWidget);
      expect(find.text('Renamed'), findsNothing);
    });

    testWidgets('applies the new title when confirmed', (tester) async {
      await pumpHistory(tester);
      await openRename(tester);

      await tester.enterText(find.byType(AppTextField), 'Renewal, renamed');
      await tester.tap(
        find.descendant(
          of: find.byType(AppPopover),
          matching: find.text('history.rename'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Renewal, renamed'), findsOneWidget);
      expect(find.text('Emirates ID Renewal'), findsNothing);
      // The row is the same conversation, not a new one.
      expect(find.byType(ConversationHistoryCard), findsNWidgets(2));
    });

    testWidgets('treats a blank name as no change', (tester) async {
      await pumpHistory(tester);
      await openRename(tester);

      await tester.enterText(find.byType(AppTextField), '   ');
      await tester.tap(
        find.descendant(
          of: find.byType(AppPopover),
          matching: find.text('history.rename'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Emirates ID Renewal'), findsOneWidget);
    });
  });

  group('motion ownership', () {
    test('the feature declares no animation durations of its own', () {
      // The rule from the brief, enforced rather than reviewed: Conversation
      // History consumes `AppSwipeActionMotion` and the shared dialog's own
      // transition, so a literal duration anywhere under the feature would be
      // a second, ungoverned motion system.
      final offenders = <String>[];
      final pattern = RegExp(
        r'Duration\s*\(\s*(milliseconds|seconds)\s*:',
      );

      for (final entity in Directory(
        'lib/src/features/history',
      ).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (pattern.hasMatch(entity.readAsStringSync())) {
          offenders.add(entity.path);
        }
      }

      expect(offenders, isEmpty);
    });
  });
}
