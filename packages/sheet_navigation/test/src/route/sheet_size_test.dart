import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

Future<void> _pumpApp(WidgetTester tester, Widget home) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(theme: AppTheme.light(), home: home),
    ),
  );
}

/// Height of the sheet's own `ConstrainedBox` (the one `ModalSheetRoute`
/// wraps its content in), located by walking up from a marker widget inside
/// the sheet — avoids accidentally matching an unrelated ConstrainedBox
/// higher up the tree (e.g. from MaterialApp/Scaffold internals).
double _sheetHeightFrom(WidgetTester tester, Finder marker) {
  return tester
      .getSize(
        find.ancestor(of: marker, matching: find.byType(ConstrainedBox)).first,
      )
      .height;
}

double _screenHeight(WidgetTester tester) =>
    tester.getSize(find.byType(MaterialApp)).height;

Widget _openerWithSettings(
  Widget Function(BuildContext) buildSheet,
  SheetRouteSettings settings,
) {
  return Builder(
    builder: (context) => Scaffold(
      body: ElevatedButton(
        onPressed: () => SheetNavigator.push<void>(
          context,
          Builder(builder: buildSheet),
          settings: settings,
        ),
        child: const Text('Open'),
      ),
    ),
  );
}

void main() {
  group('SheetSize', () {
    testWidgets(
      'content: a short 3-row menu wraps its content, well short of the screen',
      (tester) async {
        await _pumpApp(
          tester,
          _openerWithSettings(
            (_) => const Column(
              key: Key('menu'),
              mainAxisSize: MainAxisSize.min,
              children: [Text('Row 1'), Text('Row 2'), Text('Row 3')],
            ),
            const SheetRouteSettings(),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        final sheetHeight = _sheetHeightFrom(
          tester,
          find.byKey(const Key('menu')),
        );
        final screenHeight = _screenHeight(tester);

        // A 3-row menu should be nowhere near the 0.92 default ceiling.
        expect(sheetHeight, lessThan(screenHeight * 0.5));
      },
    );

    testWidgets(
      'expanded: fills the configured height fraction regardless of content',
      (tester) async {
        await _pumpApp(
          tester,
          _openerWithSettings(
            (_) => const Text('Tiny', key: Key('tiny')),
            const SheetRouteSettings(
              sheetSize: SheetSize.expanded,
              initialHeightFraction: 0.5,
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        final sheetHeight = _sheetHeightFrom(
          tester,
          find.byKey(const Key('tiny')),
        );
        final screenHeight = _screenHeight(tester);

        expect(sheetHeight, closeTo(screenHeight * 0.5, 1));
      },
    );

    testWidgets('minHeight floors a very small content sheet', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        _openerWithSettings(
          (_) => const Text('X', key: Key('x')),
          const SheetRouteSettings(minHeight: 300),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final sheetHeight = _sheetHeightFrom(tester, find.byKey(const Key('x')));
      expect(sheetHeight, greaterThanOrEqualTo(300));
    });

    testWidgets(
      'maxHeightFactor ceils very tall content instead of growing past it',
      (tester) async {
        await _pumpApp(
          tester,
          _openerWithSettings(
            (_) => SingleChildScrollView(
              key: const Key('scroller'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  100,
                  (i) => SizedBox(height: 60, child: Text('Item $i')),
                ),
              ),
            ),
            const SheetRouteSettings(maxHeightFactor: 0.5),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        final sheetHeight = _sheetHeightFrom(
          tester,
          find.byKey(const Key('scroller')),
        );
        final screenHeight = _screenHeight(tester);

        // 100 * 60px content is far taller than 0.5 * screen — it must be
        // capped, not pushed past the configured ceiling.
        expect(sheetHeight, closeTo(screenHeight * 0.5, 1));
      },
    );

    testWidgets(
      'overflow: content taller than maxHeightFactor does not throw and '
      'stays within the ceiling',
      (tester) async {
        await _pumpApp(
          tester,
          _openerWithSettings(
            (_) => SingleChildScrollView(
              key: const Key('scroller'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  200,
                  (i) => SizedBox(height: 80, child: Text('Row $i')),
                ),
              ),
            ),
            const SheetRouteSettings(maxHeightFactor: 0.6),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        final screenHeight = _screenHeight(tester);
        final sheetHeight = _sheetHeightFrom(
          tester,
          find.byKey(const Key('scroller')),
        );
        expect(sheetHeight, lessThanOrEqualTo(screenHeight * 0.6 + 1));
        // No overflow banner/error was thrown getting here — content is
        // scrollable within the clamp rather than overflowing it.
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'scrolling: tall content stays scrollable within the clamped height',
      (tester) async {
        await _pumpApp(
          tester,
          _openerWithSettings(
            (_) => SingleChildScrollView(
              key: const Key('scroller'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  50,
                  (i) => SizedBox(height: 60, child: Text('Entry $i')),
                ),
              ),
            ),
            const SheetRouteSettings(maxHeightFactor: 0.4),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        final scrollableFinder = find.descendant(
          of: find.byKey(const Key('scroller')),
          matching: find.byType(Scrollable),
        );
        final before = tester
            .state<ScrollableState>(scrollableFinder)
            .position
            .pixels;

        await tester.drag(
          find.byKey(const Key('scroller')),
          const Offset(0, -1000),
        );
        await tester.pumpAndSettle();

        final after = tester
            .state<ScrollableState>(scrollableFinder)
            .position
            .pixels;

        expect(after, greaterThan(before));
      },
    );
  });
}
