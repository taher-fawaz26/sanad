import 'package:app_animations/src/motion/app_motion.dart';
import 'package:app_animations/src/motion/app_motion_curve.dart';
import 'package:flutter/widgets.dart';

/// A slow, seamless swell — [child] eases up to a slightly larger, slightly
/// brighter peak at the half-way point and back down again, forever.
///
/// The ambient counterpart to `AppAmbientGradient`: that one *moves* a glow
/// around a page, this one keeps a mark where it is and makes it breathe.
/// Both exist because a static brand surface reads as a screenshot, and both
/// are decorative by definition — see the reduced-motion note below.
///
/// ## Why a `TweenSequence` and not two chained animations
///
/// The motion is specified as three keyframes (rest → peak → rest) with an
/// ease **between each pair**, which is not the same shape as one eased
/// `0 → 1` played forwards and reversed: a `reverse()` would ease *into* the
/// peak and out of it with the curve mirrored, putting the fastest part of
/// the motion in the wrong place. A two-item [TweenSequence] driven by a
/// single `repeat()`ing controller reproduces the keyframes exactly, and
/// because both ends of the sequence hold the same value the loop closes on
/// itself — there is no jump at the seam to design around.
///
/// ## Reduced motion
///
/// Decorative, so [AppMotion.reduceMotionOf] freezes it — to the *first*
/// frame ([minScale] / [minOpacity]), which is the same contract `AppLottie`
/// applies to a decorative illustration. No controller is created at all in
/// that case, so there is no ticker running behind a still image.
class AppBreathe extends StatefulWidget {
  /// Wraps [child] in the breathing loop.
  const AppBreathe({
    required this.child,
    super.key,
    this.period = defaultPeriod,
    this.minScale = 1,
    this.maxScale = 1.02,
    this.minOpacity = 0.85,
    this.maxOpacity = 1,
    this.curve = AppMotionCurve.standard,
  }) : assert(maxScale >= minScale, 'maxScale must not be below minScale'),
       assert(
         maxOpacity >= minOpacity,
         'maxOpacity must not be below minOpacity',
       );

  /// One full rest → peak → rest cycle.
  ///
  /// Four seconds: long enough that the eye reads it as the surface being
  /// alive rather than as something animating, which is the entire brief for
  /// an ambient loop. A local default rather than an `AppMotionDuration`
  /// entry, per that class's own rule — a duration used by one pattern is
  /// that pattern's constant, not shared vocabulary.
  static const Duration defaultPeriod = Duration(milliseconds: 4000);

  /// The subject of the animation. Rebuilt never — only its wrappers tick.
  final Widget child;

  /// One full cycle. Half of it is spent swelling, half settling back.
  final Duration period;

  /// Scale at rest, i.e. at the start and end of every cycle.
  final double minScale;

  /// Scale at the peak, half a [period] in.
  final double maxScale;

  /// Opacity at rest.
  final double minOpacity;

  /// Opacity at the peak.
  final double maxOpacity;

  /// Easing applied to each half of the cycle independently.
  ///
  /// Defaults to [AppMotionCurve.standard], which *is* CSS `ease-in-out` —
  /// `cubic-bezier(0.42, 0, 0.58, 1)` — so a motion spec written in those
  /// terms needs no translation.
  final Curve curve;

  @override
  State<AppBreathe> createState() => _AppBreatheState();
}

class _AppBreatheState extends State<AppBreathe>
    with SingleTickerProviderStateMixin {
  /// Created lazily and released the moment motion is switched off, so a
  /// reduced-motion device never pays for a ticker it cannot see.
  AnimationController? _controller;

  Animation<double>? _scale;
  Animation<double>? _opacity;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncController(animate: !AppMotion.reduceMotionOf(context));
  }

  @override
  void didUpdateWidget(AppBreathe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period ||
        oldWidget.minScale != widget.minScale ||
        oldWidget.maxScale != widget.maxScale ||
        oldWidget.minOpacity != widget.minOpacity ||
        oldWidget.maxOpacity != widget.maxOpacity ||
        oldWidget.curve != widget.curve) {
      _disposeController();
      _syncController(animate: !AppMotion.reduceMotionOf(context));
    }
  }

  void _syncController({required bool animate}) {
    if (!animate) {
      _disposeController();
      return;
    }
    if (_controller != null) return;

    final controller = AnimationController(vsync: this, duration: widget.period)
      ..repeat();
    _controller = controller;
    _scale = _sequence(widget.minScale, widget.maxScale).animate(controller);
    _opacity = _sequence(
      widget.minOpacity,
      widget.maxOpacity,
    ).animate(controller);
  }

  /// `rest → peak` then `peak → rest`, each half eased on its own, which is
  /// what a three-keyframe spec actually asks for.
  TweenSequence<double> _sequence(double rest, double peak) =>
      TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(
            begin: rest,
            end: peak,
          ).chain(CurveTween(curve: widget.curve)),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: peak,
            end: rest,
          ).chain(CurveTween(curve: widget.curve)),
          weight: 1,
        ),
      ]);

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _scale = null;
    _opacity = null;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scale;
    final opacity = _opacity;

    if (scale == null || opacity == null) {
      // Frozen at frame one. Still wrapped in the same two widgets so the
      // subtree's shape — and therefore its element tree — does not change
      // when the accessibility setting is toggled at runtime.
      return Opacity(
        opacity: widget.minOpacity,
        child: Transform.scale(scale: widget.minScale, child: widget.child),
      );
    }

    // The animation repaints a decorative surface that is, by construction,
    // behind something else; isolating it keeps whatever rides on top out of
    // the per-frame work.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller!,
        child: widget.child,
        builder: (context, child) => Opacity(
          opacity: opacity.value,
          child: Transform.scale(scale: scale.value, child: child),
        ),
      ),
    );
  }
}
