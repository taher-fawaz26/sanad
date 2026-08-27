import 'package:app_animations/app_animations.dart';
import 'package:flutter/animation.dart';

/// Applies [curve] to a `0..1` progress value `t`, clamping first so
/// out-of-range inputs (e.g. from overscroll) never produce an out-of-range
/// curve result.
double applyCollapseCurve(
  double t, {
  Curve curve = AppMotionCurve.decelerated,
}) {
  return curve.transform(t.clamp(0.0, 1.0));
}

/// Linearly maps `t` from the `[inMin, inMax]` range to `[outMin, outMax]`,
/// clamping the input first. Useful for deriving a secondary animation (e.g.
/// icon opacity) from a shared collapse-progress value over a sub-range.
double mapCollapseRange(
  double t, {
  required double inMin,
  required double inMax,
  double outMin = 0,
  double outMax = 1,
}) {
  final clamped = t.clamp(inMin, inMax);
  if (inMax == inMin) return outMax;
  final normalized = (clamped - inMin) / (inMax - inMin);
  return outMin + normalized * (outMax - outMin);
}
