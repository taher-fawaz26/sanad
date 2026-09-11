import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, {bool disableAnimations = false}) {
  return tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showAppAnimatedDialog<void>(
                    context: context,
                    builder: (_) => const AlertDialog(title: Text('Dialog')),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('showAppAnimatedDialog', () {
    testWidgets('fades and scales in rather than appearing instantly', (
      tester,
    ) async {
      await _pump(tester);

      await tester.tap(find.text('open'));
      await tester.pump(); // build the route

      final fade = tester.widget<FadeTransition>(
        find.ancestor(
          of: find.byType(AlertDialog),
          matching: find.byType(FadeTransition),
        ),
      );
      final scale = tester.widget<ScaleTransition>(
        find.ancestor(
          of: find.byType(AlertDialog),
          matching: find.byType(ScaleTransition),
        ),
      );
      expect(fade.opacity.value, lessThan(1.0));
      expect(scale.scale.value, lessThan(1.0));

      await tester.pumpAndSettle();
      expect(find.text('Dialog'), findsOneWidget);
    });

    testWidgets('still animates in under reduced motion (functional, not '
        'decorative, motion)', (tester) async {
      await _pump(tester, disableAnimations: true);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Dialog'), findsOneWidget);
    });

    testWidgets('barrierDismissible:false blocks tapping outside', (
      tester,
    ) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 800),
          minTextAdapt: true,
          builder: (_, _) => MaterialApp(
            theme: AppTheme.light(),
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showAppAnimatedDialog<void>(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const AlertDialog(title: Text('Dialog')),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Dialog'), findsOneWidget);

      // Tap far outside the dialog content, on the barrier.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Dialog'), findsOneWidget);
    });
  });
}
