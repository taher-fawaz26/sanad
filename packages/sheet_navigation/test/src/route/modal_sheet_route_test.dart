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

Widget _opener({
  required String label,
  required Widget Function(BuildContext) buildSheet,
}) {
  return Builder(
    builder: (context) => Scaffold(
      body: ElevatedButton(
        onPressed: () =>
            SheetNavigator.push<void>(context, Builder(builder: buildSheet)),
        child: Text(label),
      ),
    ),
  );
}

void main() {
  group('SheetNavigator.push', () {
    testWidgets('renders child content', (tester) async {
      await _pumpApp(
        tester,
        _opener(
          label: 'Open',
          buildSheet: (_) => const Text('Sheet content'),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Sheet content'), findsOneWidget);
    });

    testWidgets('dismisses on barrier tap when isDismissible', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => SheetNavigator.push<void>(
                context,
                const Text('Dismissible'),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Dismissible'), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Dismissible'), findsNothing);
    });

    testWidgets('does not dismiss on barrier tap when isDismissible false', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => SheetNavigator.push<void>(
                context,
                const Text('Locked'),
                settings: const SheetRouteSettings(isDismissible: false),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Locked'), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Locked'), findsOneWidget);
    });

    testWidgets('resolves the awaited future with the popped result', (
      tester,
    ) async {
      String? result;

      await _pumpApp(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await SheetNavigator.push<String>(
                  context,
                  Builder(
                    builder: (sheetContext) => ElevatedButton(
                      onPressed: () =>
                          SheetNavigator.pop(sheetContext, 'picked'),
                      child: const Text('Confirm'),
                    ),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(result, 'picked');
    });

    testWidgets('auto-dismisses when parent route is popped', (
      tester,
    ) async {
      // Simulate nested navigators (like go_router's ShellRoute):
      // the sheet goes on the ROOT navigator, while the page that
      // opened it lives on an INNER navigator.
      final innerNavKey = GlobalKey<NavigatorState>();

      await _pumpApp(
        tester,
        Navigator(
          key: innerNavKey,
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => Builder(
              builder: (pageAContext) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    innerNavKey.currentState!.push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => Builder(
                          builder: (pageBContext) => Scaffold(
                            body: ElevatedButton(
                              onPressed: () => SheetNavigator.push<void>(
                                pageBContext,
                                const Text('Sheet on page B'),
                              ),
                              child: const Text('Open sheet'),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Go to B'),
                ),
              ),
            ),
          ),
        ),
      );

      // Navigate to page B on the inner navigator.
      await tester.tap(find.text('Go to B'));
      await tester.pumpAndSettle();

      // Open the sheet from page B (pushed on root navigator).
      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();
      expect(find.text('Sheet on page B'), findsOneWidget);

      // Pop page B from the inner navigator — the sheet should be
      // auto-dismissed even though it lives on the root navigator.
      innerNavKey.currentState!.pop();
      await tester.pumpAndSettle();

      expect(find.text('Sheet on page B'), findsNothing);
      expect(find.text('Go to B'), findsOneWidget);
    });

    testWidgets('nested push morphs the previous sheet toward fullscreen', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => SheetNavigator.push<void>(
                context,
                Builder(
                  builder: (sheetContext) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Sheet A'),
                      ElevatedButton(
                        onPressed: () => SheetNavigator.push<void>(
                          sheetContext,
                          const Text('Sheet B'),
                        ),
                        child: const Text('Push B'),
                      ),
                    ],
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final screenHeight = tester.getSize(find.byType(MaterialApp)).height;
      final aBeforeHeight = tester
          .getSize(
            find
                .ancestor(
                  of: find.text('Sheet A'),
                  matching: find.byType(ConstrainedBox),
                )
                .first,
          )
          .height;
      expect(aBeforeHeight, lessThan(screenHeight));

      await tester.tap(find.text('Push B'));
      await tester.pumpAndSettle();

      expect(find.text('Sheet B'), findsOneWidget);

      final aAfterHeight = tester
          .getSize(
            find
                .ancestor(
                  of: find.text('Sheet A'),
                  matching: find.byType(ConstrainedBox),
                )
                .first,
          )
          .height;
      // Sheet A has morphed toward the previous route's fullscreen state.
      expect(aAfterHeight, greaterThan(aBeforeHeight));
    });
  });
}
