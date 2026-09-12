import 'package:app_animations/app_animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const ValueKey<String> _subjectKey = ValueKey('subject');
const _subject = SizedBox(key: _subjectKey, width: 40, height: 40);

Future<void> _pumpReveal(
  WidgetTester tester, {
  required double progress,
  bool reduceMotion = false,
  TextDirection direction = TextDirection.ltr,
}) => tester.pumpWidget(
  MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Directionality(
      textDirection: direction,
      child: AppSwipeActionReveal(
        progress: AlwaysStoppedAnimation<double>(progress),
        child: _subject,
      ),
    ),
  ),
);

Finder _inReveal(Type type) => find.descendant(
  of: find.byType(AppSwipeActionReveal),
  matching: find.byType(type),
);

double _revealOpacity(WidgetTester tester) =>
    tester.widget<Opacity>(_inReveal(Opacity)).opacity;

double _revealDx(WidgetTester tester) =>
    tester.widget<Transform>(_inReveal(Transform)).transform.storage[12];

void main() {
  group('AppSwipeActionMotion', () {
    test('every value resolves to a shared motion token', () {
      // The point of the class: a feature reads these instead of writing its
      // own `Duration(milliseconds: …)` beside a list row.
      expect(AppSwipeActionMotion.reveal, AppMotionDuration.quick);
      expect(AppSwipeActionMotion.close, AppMotionDuration.fast);
      expect(AppSwipeActionMotion.revealCurve, AppMotionCurve.decelerated);
      expect(AppSwipeActionMotion.closeCurve, AppMotionCurve.standard);
    });

    test('press feedback is restrained', () {
      // Shallower than a button's own 0.96 — a flush cell in a contiguous
      // strip must not visibly pull away from its neighbour.
      expect(AppSwipeActionMotion.pressedScale, greaterThan(0.95));
      expect(AppSwipeActionMotion.pressedScale, lessThan(1));
    });
  });

  group('AppSwipeActionReveal', () {
    testWidgets('hides the contents until the pane has travelled', (
      tester,
    ) async {
      await _pumpReveal(tester, progress: 0);
      expect(_revealOpacity(tester), 0);

      await _pumpReveal(
        tester,
        progress: AppSwipeActionMotion.contentRevealStart / 2,
      );
      expect(_revealOpacity(tester), 0);
    });

    testWidgets('settles fully open at the end of the pane travel', (
      tester,
    ) async {
      await _pumpReveal(tester, progress: 1);

      expect(_revealOpacity(tester), 1);
      expect(_revealDx(tester), 0);
    });

    testWidgets('tracks the pane rather than running its own animation', (
      tester,
    ) async {
      await _pumpReveal(tester, progress: 0.6);
      final partial = _revealOpacity(tester);

      await _pumpReveal(tester, progress: 0.8);

      // No pump between the two: the value follows the supplied progress
      // immediately, which is what lets the contents follow a finger back and
      // forth with nothing to cancel.
      expect(_revealOpacity(tester), greaterThan(partial));
      expect(partial, greaterThan(0));
    });

    testWidgets('slides in from the trailing edge in LTR', (tester) async {
      await _pumpReveal(tester, progress: 0.5);

      expect(_revealDx(tester), greaterThan(0));
      expect(
        _revealDx(tester),
        lessThanOrEqualTo(AppSwipeActionMotion.contentRevealOffset),
      );
    });

    testWidgets('mirrors in RTL', (tester) async {
      await _pumpReveal(
        tester,
        progress: 0.5,
        direction: TextDirection.rtl,
      );

      expect(_revealDx(tester), lessThan(0));
    });

    testWidgets('passes the child straight through under reduced motion', (
      tester,
    ) async {
      await _pumpReveal(tester, progress: 0, reduceMotion: true);

      // Not merely "opacity 1": the wrappers are gone entirely, so a
      // reduce-motion user sees the action from the first pixel of the drag
      // and nothing rebuilds as the pane moves.
      expect(_inReveal(Opacity), findsNothing);
      expect(find.byKey(_subjectKey), findsOneWidget);
    });
  });

  group('AppSwipeActionPress', () {
    Future<void> pump(
      WidgetTester tester, {
      bool reduceMotion = false,
    }) => tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: AppSwipeActionPress(child: _subject)),
        ),
      ),
    );

    double scale(WidgetTester tester) => tester
        .widget<AnimatedScale>(
          find.descendant(
            of: find.byType(AppSwipeActionPress),
            matching: find.byType(AnimatedScale),
          ),
        )
        .scale;

    testWidgets('scales down while a pointer is held and springs back', (
      tester,
    ) async {
      await pump(tester);
      expect(scale(tester), 1);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(_subjectKey)),
      );
      await tester.pump();
      expect(scale(tester), AppSwipeActionMotion.pressedScale);

      await gesture.up();
      await tester.pump();
      expect(scale(tester), 1);
    });

    testWidgets('resets when the gesture is cancelled', (tester) async {
      await pump(tester);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(_subjectKey)),
      );
      await tester.pump();
      await gesture.cancel();
      await tester.pump();

      expect(scale(tester), 1);
    });

    testWidgets('does not scale under reduced motion', (tester) async {
      await pump(tester, reduceMotion: true);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(_subjectKey)),
      );
      await tester.pump();

      expect(scale(tester), 1);
      await gesture.up();
    });

    testWidgets('never claims the gesture it is watching', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: GestureDetector(
              // Opaque, standing in for the `OutlinedButton` the real cell is
              // built from — a bare `SizedBox` child hit-tests nothing.
              behavior: HitTestBehavior.opaque,
              onTap: () => taps++,
              child: const AppSwipeActionPress(child: _subject),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(_subjectKey));
      await tester.pump();

      // A `GestureDetector` here would have competed in the arena with the
      // button the cell is actually built from. A `Listener` does not.
      expect(taps, 1);
    });
  });
}
