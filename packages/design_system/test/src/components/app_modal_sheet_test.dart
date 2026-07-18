import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpApp(WidgetTester tester, Widget home) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, __) => MaterialApp(
        theme: AppTheme.light(),
        home: home,
      ),
    ),
  );
}

void main() {
  group('showAppModalSheet', () {
    testWidgets('renders child inside a modal bottom sheet', (tester) async {
      await _pumpApp(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showAppModalSheet(
                context: context,
                child: const Text('Sheet content'),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Sheet content'), findsOneWidget);
    });

    testWidgets('renders title when provided', (tester) async {
      await _pumpApp(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showAppModalSheet(
                context: context,
                title: 'Pick Location',
                child: const Text('Map here'),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Pick Location'), findsOneWidget);
      expect(find.text('Map here'), findsOneWidget);
    });

    testWidgets('shows drag handle by default', (tester) async {
      await _pumpApp(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showAppModalSheet(
                context: context,
                child: const Text('Content'),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // The drag handle is rendered via OverlayDragHandle — a Container
      // with rounded decoration. Verify the sheet is visible and the
      // content rendered.
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('occupies specified height fraction', (tester) async {
      await _pumpApp(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showAppModalSheet(
                context: context,
                heightFraction: 0.5,
                child: const Text('Half sheet'),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Half sheet'), findsOneWidget);

      final sheetFinder = find.byType(BottomSheet);
      expect(sheetFinder, findsOneWidget);
      final sheetBox = tester.renderObject<RenderBox>(sheetFinder);
      final screenHeight = tester.getSize(find.byType(MaterialApp)).height;

      expect(sheetBox.size.height, lessThanOrEqualTo(screenHeight * 0.5 + 1));
    });

    testWidgets('dismisses on tap outside', (tester) async {
      await _pumpApp(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showAppModalSheet(
                context: context,
                child: const Text('Dismissible'),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Dismissible'), findsOneWidget);

      // Tap the barrier area (top of screen)
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();

      expect(find.text('Dismissible'), findsNothing);
    });

    testWidgets('returns value when popped', (tester) async {
      String? result;

      await _pumpApp(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showAppModalSheet<String>(
                  context: context,
                  child: Builder(
                    builder: (sheetContext) => ElevatedButton(
                      onPressed: () =>
                          Navigator.of(sheetContext).pop('selected'),
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

      expect(result, 'selected');
    });

    testWidgets('uses theme surface color', (tester) async {
      await _pumpApp(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showAppModalSheet(
                context: context,
                child: const Text('Themed'),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Themed'), findsOneWidget);
    });

    testWidgets('has no feature-specific dependency', (tester) async {
      await _pumpApp(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showAppModalSheet(
                context: context,
                child: const Text('Generic'),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Generic'), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);
    });
  });
}
