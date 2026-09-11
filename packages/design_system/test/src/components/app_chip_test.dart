import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

/// The interpolated decoration `AnimatedContainer` is actually painting this
/// frame — its own [AnimatedContainer.decoration] field only ever reports the
/// *target* it is animating toward, not the current in-flight value, so the
/// live value has to come from the `Container` it rebuilds internally each
/// tick.
BoxDecoration _liveDecoration(WidgetTester tester) =>
    tester
            .widget<Container>(
              find.descendant(
                of: find.byType(AnimatedContainer),
                matching: find.byType(Container),
              ),
            )
            .decoration!
        as BoxDecoration;

void main() {
  group('AppChip', () {
    testWidgets('renders its label and calls onTap on tap', (tester) async {
      var tapped = false;
      await _pump(tester, AppChip(label: 'Plumbing', onTap: () => tapped = true));

      expect(find.text('Plumbing'), findsOneWidget);

      await tester.tap(find.byType(AppChip));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets(
      'selected toggling animates the fill rather than snapping to it',
      (tester) async {
        await _pump(tester, const AppChip(label: 'Plumbing'));
        final unselectedColor = _liveDecoration(tester).color;

        await _pump(tester, const AppChip(label: 'Plumbing', selected: true));
        await tester.pumpAndSettle();
        final selectedColor = _liveDecoration(tester).color;
        expect(selectedColor, isNot(unselectedColor));

        // Toggle back and sample mid-transition: the live paint value must
        // be *between* the two endpoints, not already snapped to one of
        // them — proof the fill is genuinely being animated.
        await _pump(tester, const AppChip(label: 'Plumbing'));
        await tester.pump(const Duration(milliseconds: 40));
        final midColor = _liveDecoration(tester).color;
        expect(midColor, isNot(selectedColor));
        expect(midColor, isNot(unselectedColor));

        await tester.pumpAndSettle();
        expect(_liveDecoration(tester).color, unselectedColor);
      },
    );

    testWidgets('a chip with no onTap still renders (read-only tag use)', (
      tester,
    ) async {
      await _pump(tester, const AppChip(label: 'Read only'));
      expect(find.text('Read only'), findsOneWidget);
    });
  });
}
