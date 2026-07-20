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

Future<void> _pumpWithDisabledAnimations(
  WidgetTester tester,
  Widget child,
) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, __) => MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(body: Center(child: child)),
        ),
      ),
    ),
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('AppLoadingIndicator', () {
    // ── Rendering ────────────────────────────────────────────────────────────

    testWidgets('renders without throwing', (tester) async {
      await _pump(tester, const AppLoadingIndicator());
      expect(find.byType(AppLoadingIndicator), findsOneWidget);
    });

    testWidgets('renders a CustomPaint with correct outer size (default)', (
      tester,
    ) async {
      await _pump(tester, const AppLoadingIndicator());
      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(AppLoadingIndicator),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.width, LoadingIndicatorTokens.defaultSize);
      expect(sizedBox.height, LoadingIndicatorTokens.defaultSize);
    });

    testWidgets('respects custom size', (tester) async {
      await _pump(tester, const AppLoadingIndicator(size: 24));
      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(AppLoadingIndicator),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.width, 24.0);
      expect(sizedBox.height, 24.0);
    });

    testWidgets('contains a RepaintBoundary', (tester) async {
      await _pump(tester, const AppLoadingIndicator());
      expect(
        find.descendant(
          of: find.byType(AppLoadingIndicator),
          matching: find.byType(RepaintBoundary),
        ),
        findsOneWidget,
      );
    });

    testWidgets('contains a CustomPaint', (tester) async {
      await _pump(tester, const AppLoadingIndicator());
      expect(
        find.descendant(
          of: find.byType(AppLoadingIndicator),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    testWidgets('painter is a LoadingIndicatorPainter', (tester) async {
      await _pump(tester, const AppLoadingIndicator());
      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(AppLoadingIndicator),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(customPaint.painter, isA<LoadingIndicatorPainter>());
    });

    // ── Colour ───────────────────────────────────────────────────────────────

    testWidgets('uses custom arc color when provided', (tester) async {
      await _pump(
        tester,
        const AppLoadingIndicator(color: Colors.red),
      );
      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(AppLoadingIndicator),
          matching: find.byType(CustomPaint),
        ),
      );
      final painter = customPaint.painter! as LoadingIndicatorPainter;
      expect(painter.arcColor, Colors.red);
    });

    testWidgets('uses theme primary color as arc color by default', (
      tester,
    ) async {
      await _pump(tester, const AppLoadingIndicator());
      final context = tester.element(find.byType(AppLoadingIndicator));
      final appColors = Theme.of(context).extension<AppColors>()!;

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(AppLoadingIndicator),
          matching: find.byType(CustomPaint),
        ),
      );
      final painter = customPaint.painter! as LoadingIndicatorPainter;
      expect(painter.arcColor, appColors.primary);
    });

    // ── Stroke width ─────────────────────────────────────────────────────────

    testWidgets('uses custom strokeWidth when provided', (tester) async {
      await _pump(tester, const AppLoadingIndicator(strokeWidth: 2.0));
      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(AppLoadingIndicator),
          matching: find.byType(CustomPaint),
        ),
      );
      final painter = customPaint.painter! as LoadingIndicatorPainter;
      expect(painter.strokeWidth, 2.0);
    });

    // ── Semantics ────────────────────────────────────────────────────────────

    testWidgets('has a default semantic label', (tester) async {
      await _pump(tester, const AppLoadingIndicator());
      expect(
        tester.getSemantics(find.byType(AppLoadingIndicator)),
        matchesSemantics(label: 'Loading'),
      );
    });

    testWidgets('respects custom semanticsLabel', (tester) async {
      await _pump(
        tester,
        const AppLoadingIndicator(semanticsLabel: 'Please wait'),
      );
      expect(
        tester.getSemantics(find.byType(AppLoadingIndicator)),
        matchesSemantics(label: 'Please wait'),
      );
    });

    // ── Accessibility: reduce motion ─────────────────────────────────────────

    testWidgets('renders a static arc when disableAnimations is true', (
      tester,
    ) async {
      await _pumpWithDisabledAnimations(
        tester,
        const AppLoadingIndicator(),
      );

      // Widget still renders correctly
      expect(find.byType(AppLoadingIndicator), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppLoadingIndicator),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    // ── Animation ────────────────────────────────────────────────────────────

    testWidgets('animates — painter values change over time', (tester) async {
      await _pump(tester, const AppLoadingIndicator());

      final customPaintFinder = find.descendant(
        of: find.byType(AppLoadingIndicator),
        matching: find.byType(CustomPaint),
      );

      final painterBefore =
          tester.widget<CustomPaint>(customPaintFinder).painter!
              as LoadingIndicatorPainter;
      final rotationBefore = painterBefore.rotationAnimation.value;

      // Advance time so the rotation controller ticks.
      await tester.pump(const Duration(milliseconds: 200));

      final painterAfter =
          tester.widget<CustomPaint>(customPaintFinder).painter!
              as LoadingIndicatorPainter;
      final rotationAfter = painterAfter.rotationAnimation.value;

      // The rotation value must have advanced.
      expect(rotationAfter, isNot(equals(rotationBefore)));
    });

    // ── didUpdateWidget ───────────────────────────────────────────────────────

    testWidgets('updates strokeController duration on duration change', (
      tester,
    ) async {
      const initialDuration = Duration(milliseconds: 1500);
      const newDuration = Duration(milliseconds: 800);

      final notifier = ValueNotifier<Duration>(initialDuration);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 800),
          minTextAdapt: true,
          builder: (_, __) => MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: ValueListenableBuilder<Duration>(
                valueListenable: notifier,
                builder: (_, duration, __) =>
                    AppLoadingIndicator(duration: duration),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AppLoadingIndicator), findsOneWidget);

      notifier.value = newDuration;
      await tester.pump();

      expect(find.byType(AppLoadingIndicator), findsOneWidget);
    });

    // ── No CircularProgressIndicator dependency ───────────────────────────────

    testWidgets('does not use CircularProgressIndicator internally', (
      tester,
    ) async {
      await _pump(tester, const AppLoadingIndicator());
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
