import 'package:app_animations/app_animations.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppMotionDuration', () {
    test('values are stable (regression guard)', () {
      expect(AppMotionDuration.instant, Duration.zero);
      expect(AppMotionDuration.fast, const Duration(milliseconds: 150));
      expect(AppMotionDuration.quick, const Duration(milliseconds: 200));
      expect(AppMotionDuration.normal, const Duration(milliseconds: 300));
      expect(AppMotionDuration.emphasis, const Duration(milliseconds: 500));
      expect(
        AppMotionDuration.pageTransition,
        const Duration(milliseconds: 350),
      );
      expect(AppMotionDuration.shimmer, const Duration(milliseconds: 1200));
    });
  });

  group('AppMotionCurve', () {
    test('values are stable (regression guard)', () {
      expect(AppMotionCurve.standard, Curves.easeInOut);
      expect(AppMotionCurve.decelerated, Curves.easeOut);
      expect(AppMotionCurve.accelerated, Curves.easeIn);
      expect(AppMotionCurve.emphasizedDecelerate, Curves.easeOutCubic);
      expect(AppMotionCurve.emphasizedAccelerate, Curves.easeInCubic);
    });
  });
}
