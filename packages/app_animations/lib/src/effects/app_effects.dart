import 'package:app_animations/src/motion/app_motion.dart';
import 'package:app_animations/src/motion/app_motion_curve.dart';
import 'package:app_animations/src/motion/app_motion_duration.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Reusable entrance/emphasis effects for small, self-contained widgets.
///
/// Wraps `flutter_animate`'s effect chain with the app's motion tokens and
/// reduced-motion behavior baked in — application code should never reach
/// for `.animate()`/`flutter_animate` effects directly; that keeps the
/// animation dependency behind this package's boundary (see
/// `dep_rules.yaml`'s `flutter_animate_allowed_packages`).
///
/// Apply to the smallest widget that needs to move, never to a whole page
/// or a large subtree — each animated region invalidates its own layer, so
/// keeping animated subtrees small keeps repaint cost small. For a page-
/// level entrance use `AppPageEntrance` instead of calling these directly
/// on the page root.
extension AppEffects on Widget {
  /// Fades in from transparent. Opacity-only motion is not gated by
  /// reduced motion — a crossfade is not considered disorienting the way a
  /// translate/scale can be.
  Widget appFadeIn(
    BuildContext context, {
    Duration duration = AppMotionDuration.normal,
    Curve curve = AppMotionCurve.standard,
    Duration delay = Duration.zero,
  }) {
    return animate(delay: delay).fadeIn(duration: duration, curve: curve);
  }

  /// Fades in while sliding up a subtle amount ([distance] logical pixels).
  /// Collapses to a plain [appFadeIn] under reduced motion (opacity only,
  /// no translation).
  Widget appFadeSlideUp(
    BuildContext context, {
    Duration duration = AppMotionDuration.normal,
    Curve curve = AppMotionCurve.decelerated,
    double distance = 16,
    Duration delay = Duration.zero,
  }) {
    if (AppMotion.reduceMotionOf(context)) {
      return appFadeIn(context, duration: duration, curve: curve, delay: delay);
    }
    return animate(delay: delay)
        .fadeIn(duration: duration, curve: curve)
        .moveY(begin: distance, end: 0, duration: duration, curve: curve);
  }

  /// Fades in while sliding down a subtle amount ([distance] logical
  /// pixels). Collapses to a plain [appFadeIn] under reduced motion.
  Widget appFadeSlideDown(
    BuildContext context, {
    Duration duration = AppMotionDuration.normal,
    Curve curve = AppMotionCurve.decelerated,
    double distance = 16,
    Duration delay = Duration.zero,
  }) {
    if (AppMotion.reduceMotionOf(context)) {
      return appFadeIn(context, duration: duration, curve: curve, delay: delay);
    }
    return animate(delay: delay)
        .fadeIn(duration: duration, curve: curve)
        .moveY(begin: -distance, end: 0, duration: duration, curve: curve);
  }

  /// Fades in while scaling up from [beginScale]. Collapses to a plain
  /// [appFadeIn] under reduced motion.
  Widget appFadeScale(
    BuildContext context, {
    Duration duration = AppMotionDuration.normal,
    Curve curve = AppMotionCurve.decelerated,
    double beginScale = 0.92,
    Duration delay = Duration.zero,
  }) {
    if (AppMotion.reduceMotionOf(context)) {
      return appFadeIn(context, duration: duration, curve: curve, delay: delay);
    }
    return animate(delay: delay)
        .fadeIn(duration: duration, curve: curve)
        .scale(
          begin: Offset(beginScale, beginScale),
          end: const Offset(1, 1),
          duration: duration,
          curve: curve,
        );
  }

  /// Scales up from [beginScale] with no fade — micro tap/emphasis
  /// feedback. No-ops entirely under reduced motion (prefer
  /// `AppButtonFeedback` for interactive tap feedback; this is for a
  /// one-shot emphasis moment).
  Widget appScaleIn(
    BuildContext context, {
    Duration duration = AppMotionDuration.fast,
    Curve curve = AppMotionCurve.decelerated,
    double beginScale = 0.85,
  }) {
    if (AppMotion.reduceMotionOf(context)) return this;
    return animate().scale(
      begin: Offset(beginScale, beginScale),
      end: const Offset(1, 1),
      duration: duration,
      curve: curve,
    );
  }
}
