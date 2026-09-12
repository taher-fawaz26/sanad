import 'package:app_animations/app_animations.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';

/// `AppSwipeActionsStyle.grouped` — Figma `actions` (`8487:31503`).
///
/// The separated style's behaviour is covered by `app_swipe_actions_test`;
/// everything here is about the thing grouped exists to fix, which is that two
/// revealed actions must read as **one** surface: flush, equal, clipped to the
/// row, with no inset and no gap.

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  bool reduceMotion = false,
}) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: Directionality(
            textDirection: direction,
            child: Scaffold(body: child),
          ),
        ),
      ),
    ),
  );
}

Widget _row({
  AppSwipeActionsStyle style = AppSwipeActionsStyle.grouped,
  double? rowRadius,
  VoidCallback? onDelete,
  VoidCallback? onRename,
}) => SizedBox(
  height: 101,
  child: AppSwipeActions(
    style: style,
    rowRadius: rowRadius,
    actions: [
      AppSwipeAction(
        icon: Icons.delete_outline,
        label: 'Delete',
        semanticLabel: 'Delete',
        variant: AppSwipeActionVariant.destructive,
        onPressed: onDelete ?? () {},
      ),
      AppSwipeAction(
        icon: Icons.edit_outlined,
        label: 'Rename',
        semanticLabel: 'Rename',
        onPressed: onRename ?? () {},
      ),
    ],
    child: const ColoredBox(
      color: Color(0xFFFFFFFF),
      child: Center(child: Text('Row')),
    ),
  ),
);

Future<void> _open(
  WidgetTester tester, {
  double dx = -300,
}) async {
  await tester.drag(find.text('Row'), Offset(dx, 0), warnIfMissed: false);
  await tester.pumpAndSettle();
}

List<Rect> _cellRects(WidgetTester tester) => tester
    .widgetList<CustomSlidableAction>(find.byType(CustomSlidableAction))
    .map((cell) => tester.getRect(find.byWidget(cell)))
    .toList();

void main() {
  group('AppSwipeActions (grouped)', () {
    testWidgets('reveals both actions as one contiguous strip', (
      tester,
    ) async {
      await _pump(tester, _row());
      await _open(tester);

      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Rename'), findsOneWidget);

      final rects = _cellRects(tester);
      expect(rects, hasLength(2));

      // The seam: the first cell's trailing edge *is* the second's leading
      // edge. Any inset or spacing would show up here as a positive gap,
      // which is exactly the "separate floating pills" look this style
      // replaces.
      expect(rects[0].right, closeTo(rects[1].left, 0.01));
    });

    testWidgets('gives both actions the same width and height', (
      tester,
    ) async {
      await _pump(tester, _row());
      await _open(tester);

      final rects = _cellRects(tester);
      expect(rects[0].width, closeTo(rects[1].width, 0.01));
      expect(rects[0].height, closeTo(rects[1].height, 0.01));
      expect(rects[0].top, closeTo(rects[1].top, 0.01));
      expect(rects[0].bottom, closeTo(rects[1].bottom, 0.01));
      // Full row height, not a pill inset inside it.
      expect(rects[0].height, closeTo(101, 0.01));
    });

    testWidgets('centres each icon and label inside its cell', (tester) async {
      await _pump(tester, _row());
      await _open(tester);

      final rects = _cellRects(tester);
      for (final (index, label) in ['Delete', 'Rename'].indexed) {
        final content = tester.getRect(find.text(label));
        expect(content.center.dx, closeTo(rects[index].center.dx, 1));
      }

      // The glyph sits above its caption, both inside the cell's own box.
      final icon = tester.getRect(find.byIcon(Icons.delete_outline));
      final caption = tester.getRect(find.text('Delete'));
      expect(icon.bottom, lessThanOrEqualTo(caption.top));
      expect(rects[0].contains(icon.center), isTrue);
    });

    testWidgets('paints the fill on the cell itself, not on an inset pill', (
      tester,
    ) async {
      await _pump(tester, _row());
      await _open(tester);

      final cells = tester
          .widgetList<CustomSlidableAction>(find.byType(CustomSlidableAction))
          .toList();

      final colors = AppTheme.light().extension<AppColors>()!;
      // Destructive stays destructive — the design system's own error token,
      // the same one the confirmation dialog's CTA uses.
      expect(cells[0].backgroundColor, colors.error);
      expect(cells[0].foregroundColor, colors.onError);
      // Figma's `#F7F9FA` on `#5C6C75` — `sky/50` and `sky/600`.
      expect(cells[1].backgroundColor, colors.palettes.sky.shade50);
      expect(cells[1].foregroundColor, colors.palettes.sky.shade600);
      // No per-cell radius: the group is clipped once, as a whole.
      expect(cells[0].borderRadius, BorderRadius.zero);
      expect(cells[1].borderRadius, BorderRadius.zero);
    });

    testWidgets('clips the strip to the row shape', (tester) async {
      await _pump(tester, _row(rowRadius: 20));
      await _open(tester);

      final expected = SwipeActionsTokens.groupedBorderRadius(
        rowRadius: 20,
      ).resolve(TextDirection.ltr);

      final clips = tester
          .widgetList<ClipRRect>(find.byType(ClipRRect))
          .map((clip) => clip.borderRadius)
          .toList();

      expect(clips, contains(expected));
      // The row's own corner on the outer edge — the caller's value, used as
      // given, because the row has already resolved it for its own card.
      expect(expected.topRight.x, 20);
      // A tighter, component-owned 12 where the card slides away from it.
      expect(expected.topLeft.x, closeTo(responsiveDimension(12), 0.01));
    });

    testWidgets('keeps Delete on the leading edge of the strip in LTR', (
      tester,
    ) async {
      await _pump(tester, _row());
      await _open(tester);

      expect(
        tester.getCenter(find.text('Delete')).dx,
        lessThan(tester.getCenter(find.text('Rename')).dx),
      );
    });

    testWidgets('mirrors the strip in RTL without reordering the actions', (
      tester,
    ) async {
      await _pump(tester, _row(), direction: TextDirection.rtl);
      await _open(tester, dx: 300);

      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Rename'), findsOneWidget);

      // Leading edge is the right-hand one under RTL, so Delete is now the
      // rightmost cell — the same logical order, mirrored.
      expect(
        tester.getCenter(find.text('Delete')).dx,
        greaterThan(tester.getCenter(find.text('Rename')).dx),
      );

      // Still flush, just the other way round.
      final rects = _cellRects(tester);
      expect(rects[0].left, closeTo(rects[1].right, 0.01));
    });

    testWidgets('drives the reveal from the shared motion primitive', (
      tester,
    ) async {
      await _pump(tester, _row());
      await _open(tester);

      // Not "it animates" — specifically that the feature's motion comes from
      // `app_animations`, so no duration lives in this component or its
      // callers.
      expect(find.byType(AppSwipeActionReveal), findsNWidgets(2));
      expect(find.byType(AppSwipeActionPress), findsNWidgets(2));
    });

    testWidgets('shows the contents immediately under reduced motion', (
      tester,
    ) async {
      await _pump(tester, _row(), reduceMotion: true);
      await _open(tester);

      expect(find.text('Delete'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppSwipeActionReveal),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
    });

    testWidgets('closes the pane and fires the callback on tap', (
      tester,
    ) async {
      var deletes = 0;
      await _pump(tester, _row(onDelete: () => deletes++));

      await _open(tester);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(deletes, 1);
      expect(find.text('Delete'), findsNothing);
      // The pane closed itself; nothing is left mid-animation.
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('survives repeated open/close cycles without leaking state', (
      tester,
    ) async {
      var renames = 0;
      await _pump(tester, _row(onRename: () => renames++));

      Rect? firstOpenSeam;
      for (var cycle = 0; cycle < 3; cycle++) {
        await _open(tester);
        expect(find.text('Rename'), findsOneWidget);
        // Never more than one pane's worth of cells, however many times the
        // row has been opened.
        expect(find.byType(CustomSlidableAction), findsNWidgets(2));

        final rects = _cellRects(tester);
        firstOpenSeam ??= rects[0];
        // Geometry is identical every time: no drift, no residue from the
        // previous cycle's controller.
        expect(rects[0], firstOpenSeam);
        expect(rects[0].right, closeTo(rects[1].left, 0.01));

        // Choosing an action closes the pane — the app's only close path
        // besides the user dragging it back.
        await tester.tap(find.text('Rename'));
        await tester.pumpAndSettle();
        expect(find.text('Rename'), findsNothing);
        // Nothing left ticking between cycles.
        expect(tester.binding.hasScheduledFrame, isFalse);
      }

      expect(renames, 3);
      expect(tester.takeException(), isNull);
    });

    testWidgets('separated style is unchanged: inset pills, clear cell', (
      tester,
    ) async {
      await _pump(tester, _row(style: AppSwipeActionsStyle.separated));
      await _open(tester);

      final cells = tester
          .widgetList<CustomSlidableAction>(find.byType(CustomSlidableAction))
          .toList();

      expect(cells[0].backgroundColor, Colors.transparent);
      expect(cells[0].borderRadius, SwipeActionsTokens.borderRadius());
      // The pill's own margin is what opens the gap grouped removes.
      final pill = tester.widget<Container>(
        find
            .descendant(
              of: find.byWidget(cells[0]),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(pill.margin, isNotNull);
      expect(find.byType(AppSwipeActionReveal), findsNothing);
    });
  });
}
