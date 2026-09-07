import 'package:app_animations/src/motion/app_motion.dart';
import 'package:app_animations/src/motion/app_motion_curve.dart';
import 'package:app_animations/src/motion/app_motion_duration.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A [Column] whose children fade/slide in one after another with a bounded,
/// staggered delay — the standard "content hierarchy entrance" for a
/// content-only screen (title → subtitle → field → …).
///
/// **Runs once per mount.** The decision to animate is made on this widget's
/// very first `build()` and cached in its `State`, so later rebuilds — a
/// keyboard opening, a validator flipping an error, a `BlocBuilder`
/// re-emitting — return the children in a plain [Column] with no motion. The
/// entrance therefore never replays and never re-schedules timers on rebuild.
///
/// Only the first [maxStaggered] children are staggered; any beyond it enter
/// together with the last staggered one (auth screens have few hierarchy
/// items, so this simply caps a pathological case). Keep the child count
/// small — this is for a screen's hierarchy, not a long list (use
/// `AppListEntrance` for list/grid items).
///
/// Under reduced motion the children render immediately in a plain [Column]
/// with no entrance motion and no pending timers — content and hierarchy stay
/// fully visible, only the motion is removed.
class AppStaggeredColumn extends StatefulWidget {
  const AppStaggeredColumn({
    required this.children,
    super.key,
    this.step = const Duration(milliseconds: 50),
    this.maxStaggered = 6,
    this.duration = AppMotionDuration.normal,
    this.curve = AppMotionCurve.decelerated,
    this.distance = 12,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  /// The column's children, in the order they should enter.
  final List<Widget> children;

  /// Delay added per child, up to [maxStaggered].
  final Duration step;

  /// Children at or beyond this index share the last staggered delay rather
  /// than continuing to accumulate.
  final int maxStaggered;

  final Duration duration;
  final Curve curve;
  final double distance;

  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  State<AppStaggeredColumn> createState() => _AppStaggeredColumnState();
}

class _AppStaggeredColumnState extends State<AppStaggeredColumn> {
  bool _played = false;

  @override
  Widget build(BuildContext context) {
    final shouldAnimate = !_played && !AppMotion.reduceMotionOf(context);
    _played = true;

    return Column(
      mainAxisAlignment: widget.mainAxisAlignment,
      mainAxisSize: widget.mainAxisSize,
      crossAxisAlignment: widget.crossAxisAlignment,
      children: shouldAnimate ? _animatedChildren(context) : widget.children,
    );
  }

  List<Widget> _animatedChildren(BuildContext context) {
    // Stagger via EFFECT-level delay on a single `Animate` timeline, never the
    // `Animate(delay:)` constructor: the latter schedules a `Future.delayed`
    // Timer that outlives a short/bounded-pump widget test (the OTP screen
    // pumps in bounded steps, never `pumpAndSettle`, because of its repeating
    // caret) and trips "a Timer is still pending". An effect delay is folded
    // into the animation controller's own timeline instead, so the whole
    // entrance is a single Ticker that disposes cleanly with the widget.
    return [
      for (final (index, child) in widget.children.indexed)
        _staggered(child, widget.step * index.clamp(0, widget.maxStaggered)),
    ];
  }

  Widget _staggered(Widget child, Duration delay) {
    return child
        .animate()
        .fadeIn(
          delay: delay,
          duration: widget.duration,
          curve: AppMotionCurve.standard,
        )
        .moveY(
          begin: widget.distance,
          end: 0,
          delay: delay,
          duration: widget.duration,
          curve: widget.curve,
        );
  }
}
