import 'package:app_animations/app_animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The motion specification this widget exists to reproduce:
/// loop, 4000ms, scale 1 → 1.02 → 1, opacity 85% → 100% → 85%, eased
/// `cubic-bezier(0.42, 0, 0.58, 1)` between keyframes.
const _period = Duration(milliseconds: 4000);

Future<void> _pump(
  WidgetTester tester, {
  bool reduceMotion = false,
  Widget child = const SizedBox(width: 10, height: 10),
}) => tester.pumpWidget(
  MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: AppBreathe(child: child),
    ),
  ),
);

double _opacity(WidgetTester tester) => tester
    .widget<Opacity>(
      find.descendant(
        of: find.byType(AppBreathe),
        matching: find.byType(Opacity),
      ),
    )
    .opacity;

/// `Transform.scale` writes a uniform scale into the matrix, so reading
/// `[0]` reads the scale factor back out.
double _scale(WidgetTester tester) => tester
    .widget<Transform>(
      find.descendant(
        of: find.byType(AppBreathe),
        matching: find.byType(Transform),
      ),
    )
    .transform
    .storage[0];

void main() {
  group('AppBreathe', () {
    testWidgets('starts at the resting keyframe', (tester) async {
      await _pump(tester);

      expect(_scale(tester), closeTo(1, 0.0001));
      expect(_opacity(tester), closeTo(0.85, 0.0001));
    });

    testWidgets('peaks at 1.02 scale and full opacity mid-cycle', (
      tester,
    ) async {
      await _pump(tester);
      await tester.pump(_period ~/ 2);

      expect(_scale(tester), closeTo(1.02, 0.0001));
      expect(_opacity(tester), closeTo(1, 0.0001));
    });

    testWidgets('returns to the resting keyframe at the end of the cycle', (
      tester,
    ) async {
      await _pump(tester);
      await tester.pump(_period ~/ 2);
      await tester.pump(_period ~/ 2);

      // The loop's seam: both ends of the sequence hold the same value, so a
      // repeat has nothing to jump over.
      expect(_scale(tester), closeTo(1, 0.0001));
      expect(_opacity(tester), closeTo(0.85, 0.0001));
    });

    testWidgets('keeps looping past one period', (tester) async {
      await _pump(tester);
      await tester.pump(_period);
      await tester.pump(_period ~/ 2);

      expect(_scale(tester), closeTo(1.02, 0.0001));
      expect(_opacity(tester), closeTo(1, 0.0001));
    });

    testWidgets('stays inside the specified bounds throughout a cycle', (
      tester,
    ) async {
      await _pump(tester);

      for (var step = 0; step < 20; step++) {
        await tester.pump(_period ~/ 20);
        expect(_scale(tester), inInclusiveRange(1, 1.02));
        expect(_opacity(tester), inInclusiveRange(0.85, 1));
      }
    });

    testWidgets('eases rather than moving linearly', (tester) async {
      await _pump(tester);
      // A quarter of the way into the swell, `easeInOut` is still well below
      // the linear half-way point — which is the difference between the
      // specified cubic-bezier and no curve at all.
      await tester.pump(_period ~/ 8);

      final quarter = (_scale(tester) - 1) / 0.02;
      expect(quarter, lessThan(0.4));
    });

    testWidgets('freezes at frame one under reduced motion', (tester) async {
      await _pump(tester, reduceMotion: true);

      expect(_scale(tester), closeTo(1, 0.0001));
      expect(_opacity(tester), closeTo(0.85, 0.0001));

      await tester.pump(_period ~/ 2);

      expect(_scale(tester), closeTo(1, 0.0001));
      expect(_opacity(tester), closeTo(0.85, 0.0001));
    });

    testWidgets('runs no ticker under reduced motion', (tester) async {
      await _pump(tester, reduceMotion: true);

      // A repeating controller keeps a frame scheduled forever; without one,
      // the binding has nothing left to do. This is what stops a frozen
      // decoration from costing a vsync callback per frame.
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('keeps the child in the tree in both modes', (tester) async {
      const child = SizedBox(key: ValueKey('subject'), width: 10, height: 10);

      await _pump(tester, child: child);
      expect(find.byKey(const ValueKey('subject')), findsOneWidget);

      await _pump(tester, reduceMotion: true, child: child);
      expect(find.byKey(const ValueKey('subject')), findsOneWidget);
    });

    testWidgets('disposes its controller without leaking a ticker', (
      tester,
    ) async {
      await _pump(tester);
      await tester.pump(_period ~/ 3);
      await tester.pumpWidget(const SizedBox.shrink());

      // `SingleTickerProviderStateMixin` asserts loudly if its ticker is
      // still active when the state is disposed, so unmounting mid-cycle
      // without an exception *is* the assertion here.
      expect(tester.takeException(), isNull);
      expect(find.byType(AppBreathe), findsNothing);
    });

    test('defaults match the supplied motion specification', () {
      const breathe = AppBreathe(child: SizedBox.shrink());

      expect(AppBreathe.defaultPeriod, _period);
      expect(breathe.period, _period);
      expect(breathe.minScale, 1);
      expect(breathe.maxScale, 1.02);
      expect(breathe.minOpacity, 0.85);
      expect(breathe.maxOpacity, 1);
      // `cubic-bezier(0.42, 0, 0.58, 1)` *is* CSS ease-in-out, which is the
      // shared `standard` token — no new curve was introduced for this.
      expect(breathe.curve, AppMotionCurve.standard);
      expect(AppMotionCurve.standard, Curves.easeInOut);
    });
  });
}
