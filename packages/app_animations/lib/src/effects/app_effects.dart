import 'dart:math' as math;

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

  /// A subtle one-shot horizontal shake — deliberately small "wrong, try
  /// again" feedback for a rejected entry. Scoped to the OTP field on an
  /// invalid/expired code; not a general validation effect (calm error text
  /// covers the rest). The movement is a few logical pixels only ([amount]
  /// offset) so it never shifts page layout, and it plays once per change of
  /// [trigger] rather than repeating.
  ///
  /// [trigger] must change value to (re)play the shake — pass the id/hash of
  /// the current error so a new rejection re-fires it and an unrelated
  /// rebuild does not. No-op entirely under reduced motion (the error text
  /// still conveys the failure).
  ///
  /// Built on an implicit [TweenAnimationBuilder] (a `Ticker`, disposed with
  /// the widget) rather than `flutter_animate` on purpose: a `flutter_animate`
  /// `Animate` schedules a `Future.delayed` timer on mount, and this effect is
  /// used on the OTP field, whose screen is pumped in bounded steps (never
  /// `pumpAndSettle`, because of its repeating caret) — a stray timer created
  /// as the error appears would outlive the test. This leaves no pending
  /// timer.
  Widget appShake(
    BuildContext context, {
    required Object? trigger,
    Duration duration = AppMotionDuration.fast,
    double amount = 2,
  }) {
    if (trigger == null || AppMotion.reduceMotionOf(context)) return this;
    return _AppShake(
      trigger: trigger,
      duration: duration,
      amount: amount,
      child: this,
    );
  }
}

/// A subtle, one-shot damped horizontal shake that replays whenever [trigger]
/// changes (the `ValueKey` remounts the animation), and settles back to zero
/// offset. Implicit/`Ticker`-based — no timer, no explicit controller.
class _AppShake extends StatelessWidget {
  const _AppShake({
    required this.trigger,
    required this.duration,
    required this.amount,
    required this.child,
  });

  final Object trigger;
  final Duration duration;
  final double amount;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(trigger),
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: AppMotionCurve.standard,
      builder: (context, t, child) {
        // Damped sine: a couple of oscillations whose amplitude decays to 0 as
        // t → 1, so the field ends exactly where it started (no layout shift).
        final dx = math.sin(t * math.pi * 3) * amount * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: child,
    );
  }
}
