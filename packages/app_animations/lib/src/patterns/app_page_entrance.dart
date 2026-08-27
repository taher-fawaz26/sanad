import 'package:app_animations/src/effects/app_effects.dart';
import 'package:app_animations/src/motion/app_motion_curve.dart';
import 'package:app_animations/src/motion/app_motion_duration.dart';
import 'package:flutter/widgets.dart';

/// Standard page-entrance motion: fade in + a subtle upward translate.
///
/// Opt-in — wrap a page's body with this only when the page benefits from
/// it (e.g. a fresh, content-only screen); do not wrap every page by
/// default. Keep the movement subtle — the default [distance] is a few
/// logical pixels, not a slide-in-from-offscreen effect.
class AppPageEntrance extends StatelessWidget {
  const AppPageEntrance({
    required this.child,
    super.key,
    this.duration = AppMotionDuration.normal,
    this.curve = AppMotionCurve.decelerated,
    this.distance = 12,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;
  final double distance;

  @override
  Widget build(BuildContext context) {
    return child.appFadeSlideUp(
      context,
      duration: duration,
      curve: curve,
      distance: distance,
    );
  }
}
