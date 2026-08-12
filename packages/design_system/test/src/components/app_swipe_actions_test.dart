import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  TextDirection direction = TextDirection.ltr,
}) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, __) => MaterialApp(
        theme: AppTheme.light(),
        home: Directionality(
          textDirection: direction,
          child: Scaffold(body: child),
        ),
      ),
    ),
  );
}

Widget _row({
  required List<AppSwipeAction> actions,
  String? groupTag,
  Key? key,
}) {
  return SizedBox(
    height: 72,
    child: AppSwipeActions(
      key: key,
      groupTag: groupTag,
      actions: actions,
      child: const ListTile(title: Text('Row')),
    ),
  );
}

Future<void> _openPane(
  WidgetTester tester,
  Finder finder, {
  double dx = -300,
}) async {
  // warnIfMissed: false — once a sibling row's pane is open, flutter_slidable
  // covers the screen with a tap-outside-to-close barrier that the plain hit
  // test flags as "missed", even though the drag still reaches this row.
  await tester.drag(finder, Offset(dx, 0), warnIfMissed: false);
  await tester.pumpAndSettle();
}

void main() {
  group('AppSwipeActions', () {
    testWidgets('renders child', (tester) async {
      await _pump(
        tester,
        _row(
          actions: [
            AppSwipeAction(
              icon: Icons.edit,
              semanticLabel: 'Edit',
              onPressed: () {},
            ),
          ],
        ),
      );

      expect(find.text('Row'), findsOneWidget);
    });

    testWidgets('renders no Slidable pane when actions is empty', (
      tester,
    ) async {
      await _pump(tester, _row(actions: const []));

      expect(find.text('Row'), findsOneWidget);
      expect(find.byType(Slidable), findsNothing);
    });

    testWidgets('renders 1 action', (tester) async {
      await _pump(
        tester,
        _row(
          actions: [
            AppSwipeAction(
              icon: Icons.edit,
              semanticLabel: 'Edit',
              onPressed: () {},
            ),
          ],
        ),
      );

      await _openPane(tester, find.text('Row'));

      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('renders 2 actions in order', (tester) async {
      final tapped = <String>[];
      await _pump(
        tester,
        _row(
          actions: [
            AppSwipeAction(
              icon: Icons.edit,
              semanticLabel: 'Edit',
              onPressed: () => tapped.add('edit'),
            ),
            AppSwipeAction(
              icon: Icons.delete,
              semanticLabel: 'Delete',
              variant: AppSwipeActionVariant.destructive,
              onPressed: () => tapped.add('delete'),
            ),
          ],
        ),
      );

      await _openPane(tester, find.text('Row'));

      final editCenter = tester.getCenter(find.byIcon(Icons.edit));
      final deleteCenter = tester.getCenter(find.byIcon(Icons.delete));
      expect(editCenter.dx, lessThan(deleteCenter.dx));
    });

    testWidgets('renders 3 actions', (tester) async {
      await _pump(
        tester,
        _row(
          actions: [
            AppSwipeAction(
              icon: Icons.edit,
              semanticLabel: 'Edit',
              onPressed: () {},
            ),
            AppSwipeAction(
              icon: Icons.pause,
              semanticLabel: 'Suspend',
              variant: AppSwipeActionVariant.warning,
              onPressed: () {},
            ),
            AppSwipeAction(
              icon: Icons.delete,
              semanticLabel: 'Delete',
              variant: AppSwipeActionVariant.destructive,
              onPressed: () {},
            ),
          ],
        ),
      );

      await _openPane(tester, find.text('Row'));

      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('tap invokes correct callback', (tester) async {
      var editCount = 0;
      var deleteCount = 0;
      await _pump(
        tester,
        _row(
          actions: [
            AppSwipeAction(
              icon: Icons.edit,
              semanticLabel: 'Edit',
              onPressed: () => editCount++,
            ),
            AppSwipeAction(
              icon: Icons.delete,
              semanticLabel: 'Delete',
              variant: AppSwipeActionVariant.destructive,
              onPressed: () => deleteCount++,
            ),
          ],
        ),
      );

      await _openPane(tester, find.text('Row'));
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(deleteCount, 1);
      expect(editCount, 0);
    });

    testWidgets('disabled action does not invoke callback', (tester) async {
      var count = 0;
      await _pump(
        tester,
        _row(
          actions: [
            AppSwipeAction(
              icon: Icons.delete,
              semanticLabel: 'Delete',
              variant: AppSwipeActionVariant.destructive,
              enabled: false,
              onPressed: () => count++,
            ),
          ],
        ),
      );

      await _openPane(tester, find.text('Row'));
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(count, 0);
    });

    testWidgets('exposes semantic labels for accessibility', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        _row(
          actions: [
            AppSwipeAction(
              icon: Icons.edit,
              semanticLabel: 'Edit worker',
              onPressed: () {},
            ),
          ],
        ),
      );

      await _openPane(tester, find.text('Row'));

      expect(find.bySemanticsLabel('Edit worker'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('RTL: dragging start-to-end reveals the action pane', (
      tester,
    ) async {
      await _pump(
        tester,
        _row(
          actions: [
            AppSwipeAction(
              icon: Icons.edit,
              semanticLabel: 'Edit',
              onPressed: () {},
            ),
          ],
        ),
        direction: TextDirection.rtl,
      );

      // In RTL the logical "end" pane is revealed by dragging left-to-right.
      await _openPane(tester, find.text('Row'), dx: 300);

      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets(
      'opening one row in a group auto-closes the previously open row',
      (tester) async {
        await _pump(
          tester,
          AppSwipeActionsGroup(
            child: Column(
              children: [
                _row(
                  key: const ValueKey('a'),
                  groupTag: 'rows',
                  actions: [
                    AppSwipeAction(
                      icon: Icons.edit,
                      semanticLabel: 'Edit A',
                      onPressed: () {},
                    ),
                  ],
                ),
                _row(
                  key: const ValueKey('b'),
                  groupTag: 'rows',
                  actions: [
                    AppSwipeAction(
                      icon: Icons.delete,
                      semanticLabel: 'Delete B',
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

        final rowA = find.descendant(
          of: find.byKey(const ValueKey('a')),
          matching: find.text('Row'),
        );
        final rowB = find.descendant(
          of: find.byKey(const ValueKey('b')),
          matching: find.text('Row'),
        );

        await _openPane(tester, rowA);
        expect(find.byIcon(Icons.edit), findsOneWidget);

        await _openPane(tester, rowB);
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.delete), findsOneWidget);
        expect(find.byIcon(Icons.edit), findsNothing);
      },
    );
  });
}
