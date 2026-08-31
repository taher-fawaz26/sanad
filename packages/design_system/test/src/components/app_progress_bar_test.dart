import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

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

// `Container(color: ...)` (no explicit `decoration`) renders via an internal
// `ColoredBox`, not a `DecoratedBox` — so the track/fill colors are read off
// `ColoredBox.color`, not `Container.decoration`.
Finder _coloredBoxesInBar() => find.descendant(
  of: find.byType(AppProgressBar),
  matching: find.byType(ColoredBox),
);

ColoredBox _track(WidgetTester tester) =>
    tester.widgetList<ColoredBox>(_coloredBoxesInBar()).first;

ColoredBox _fill(WidgetTester tester) =>
    tester.widgetList<ColoredBox>(_coloredBoxesInBar()).last;

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('AppProgressBar', () {
    testWidgets('uses theme-default height/colors when no override is given', (
      tester,
    ) async {
      await _pump(tester, const AppProgressBar(value: 0.5));

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(AppProgressBar),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.height, responsiveDimension(ProgressTokens.height));
    });

    testWidgets('height/trackColor/fillColor/borderRadius overrides are '
        'honored', (tester) async {
      const trackColor = Color(0xFFEBEBEC);
      const fillColor = Color(0xFF1A7A66);

      await _pump(
        tester,
        AppProgressBar(
          value: 0.2,
          height: 8,
          trackColor: trackColor,
          fillColor: fillColor,
          borderRadius: BorderRadius.circular(4),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(AppProgressBar),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.height, 8);
      expect(_track(tester).color, trackColor);
      expect(_fill(tester).color, fillColor);

      final clip = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clip.borderRadius, BorderRadius.circular(4));
    });

    testWidgets('clamps value within [min, max]', (tester) async {
      await _pump(tester, const AppProgressBar(value: 5));

      final fractionallySizedBox = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(fractionallySizedBox.widthFactor, 1.0);
    });
  });
}
