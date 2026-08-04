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

/// Builds a chain of three nested sheets: A pushes B, B pushes C. Each body
/// shows its own label plus a button to push the next level, so the test can
/// drive the whole A → B → C → pop → pop → pop stack.
Widget _sheetA(BuildContext context) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text('Sheet A'),
      ElevatedButton(
        onPressed: () => SheetNavigator.push<void>(
          context,
          const Builder(builder: _sheetB),
        ),
        child: const Text('Push B'),
      ),
    ],
  );
}

Widget _sheetB(BuildContext context) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text('Sheet B'),
      ElevatedButton(
        onPressed: () => SheetNavigator.push<String>(
          context,
          const Builder(builder: _sheetC),
        ),
        child: const Text('Push C'),
      ),
    ],
  );
}

Widget _sheetC(BuildContext context) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text('Sheet C'),
      ElevatedButton(
        onPressed: () => SheetNavigator.pop(context, 'from-C'),
        child: const Text('Pop with value'),
      ),
    ],
  );
}

void main() {
  group('nested sheet back stack', () {
    testWidgets('A -> B -> C, then pop back through each level in order', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => SheetNavigator.push<void>(
                context,
                const Builder(builder: _sheetA),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Sheet A'), findsOneWidget);

      await tester.tap(find.text('Push B'));
      await tester.pumpAndSettle();
      expect(find.text('Sheet B'), findsOneWidget);

      await tester.tap(find.text('Push C'));
      await tester.pumpAndSettle();
      expect(find.text('Sheet C'), findsOneWidget);

      // Simulate the Android hardware back button — pops C, back to B.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Sheet C'), findsNothing);
      expect(find.text('Sheet B'), findsOneWidget);

      // Back again — pops B, back to A.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Sheet B'), findsNothing);
      expect(find.text('Sheet A'), findsOneWidget);

      // Back again — pops A, back to the original page.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Sheet A'), findsNothing);
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets(
      "a value popped from the deepest sheet resolves that sheet's own future",
      (tester) async {
        String? valueFromB;

        await _pumpApp(
          tester,
          Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => SheetNavigator.push<void>(
                  context,
                  Builder(
                    builder: (sheetAContext) => ElevatedButton(
                      onPressed: () async {
                        valueFromB = await SheetNavigator.push<String>(
                          sheetAContext,
                          const Builder(builder: _sheetC),
                        );
                      },
                      child: const Text('Push C from A'),
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

        await tester.tap(find.text('Push C from A'));
        await tester.pumpAndSettle();
        expect(find.text('Sheet C'), findsOneWidget);

        await tester.tap(find.text('Pop with value'));
        await tester.pumpAndSettle();

        expect(valueFromB, 'from-C');
        // Popping C resolves only C's own future — A is still open.
        expect(find.text('Push C from A'), findsOneWidget);
      },
    );
  });
}
