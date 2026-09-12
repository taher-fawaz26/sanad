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
      builder: (_, __) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

Finder _semanticsOf(Finder of) =>
    find.descendant(of: of, matching: find.byType(Semantics)).first;

Material _materialOf(WidgetTester tester) => tester.widget<Material>(
  find
      .descendant(of: find.byType(AppButton), matching: find.byType(Material))
      .first,
);

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('AppButton', () {
    testWidgets('renders its label and calls onPressed on tap', (
      tester,
    ) async {
      var tapped = false;
      await _pump(
        tester,
        AppButton(label: 'Confirm', onPressed: () => tapped = true),
      );

      expect(find.text('Confirm'), findsOneWidget);

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('onPressed null disables the button and blocks taps', (
      tester,
    ) async {
      await _pump(tester, const AppButton(label: 'Confirm', onPressed: null));

      final semantics = tester.widget<Semantics>(
        _semanticsOf(find.byType(AppButton)),
      );
      expect(semantics.properties.enabled, isFalse);

      // No exception, and no onPressed to call — tap is a no-op.
      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      await tester.pump();
    });

    testWidgets('isLoading hides the label, shows a spinner, blocks taps', (
      tester,
    ) async {
      var tapped = false;
      await _pump(
        tester,
        AppButton(
          label: 'Confirm',
          isLoading: true,
          onPressed: () => tapped = true,
        ),
      );

      expect(find.text('Confirm'), findsNothing);
      expect(find.byType(AppLoadingIndicator), findsOneWidget);

      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      await tester.pump();
      expect(tapped, isFalse);
    });

    testWidgets('exposes button semantics for accessibility', (tester) async {
      await _pump(tester, AppButton(label: 'Confirm', onPressed: () {}));

      final semantics = tester.widget<Semantics>(
        _semanticsOf(find.byType(AppButton)),
      );
      expect(semantics.properties.button, isTrue);
      expect(semantics.properties.enabled, isTrue);
    });

    testWidgets('variant + intent are orthogonal — outline + destructive', (
      tester,
    ) async {
      await _pump(
        tester,
        AppButton(
          label: 'Delete',
          variant: AppButtonVariant.outline,
          intent: AppButtonIntent.destructive,
          onPressed: () {},
        ),
      );

      final material = _materialOf(tester);
      expect(material.color, Colors.transparent);
      expect(material.shape, isA<RoundedRectangleBorder>());
      final shape = material.shape! as RoundedRectangleBorder;
      expect(shape.side, isNot(BorderSide.none));
    });

    testWidgets('block size stretches to full width', (tester) async {
      await _pump(
        tester,
        AppButton(label: 'Confirm', onPressed: () {}),
      );
      expect(
        find.byType(SizedBox).evaluate().any((e) {
          final sizedBox = e.widget as SizedBox;
          return sizedBox.width == double.infinity;
        }),
        isTrue,
      );
    });

    testWidgets('AppButtonPresets.outline sets the outline variant', (
      tester,
    ) async {
      final button = AppButtonPresets.outline(label: 'Retry', onPressed: () {});
      expect(button.variant, AppButtonVariant.outline);
      expect(button.intent, AppButtonIntent.standard);
    });

    testWidgets('press scales the button down; release restores it', (
      tester,
    ) async {
      await _pump(tester, AppButton(label: 'Confirm', onPressed: () {}));

      AnimatedScale scaleOf() =>
          tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(scaleOf().scale, 1.0);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(AppButton)),
      );
      await tester.pump();
      expect(scaleOf().scale, lessThan(1.0));

      await gesture.up();
      await tester.pump();
      expect(scaleOf().scale, 1.0);
    });

    testWidgets('a disabled button never scales on press', (tester) async {
      await _pump(tester, const AppButton(label: 'Confirm', onPressed: null));

      // Disabled: InkWell's onTapDown/onHighlightChanged are both null, so
      // `_pressed` can never become true regardless of the gesture below.
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(AppButton)),
      );
      await tester.pump();
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        1.0,
      );
      await gesture.up();
    });

    testWidgets('reduced motion keeps the button at full scale while pressed', (
      tester,
    ) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 800),
          minTextAdapt: true,
          builder: (_, _) => MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: MaterialApp(
              theme: AppTheme.light(),
              home: Scaffold(
                body: Center(
                  child: AppButton(label: 'Confirm', onPressed: () {}),
                ),
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(AppButton)),
      );
      await tester.pump();
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        1.0,
      );
      await gesture.up();
    });
  });
}
