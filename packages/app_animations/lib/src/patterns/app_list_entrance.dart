import 'package:app_animations/src/effects/app_effects.dart';
import 'package:app_animations/src/motion/app_motion.dart';
import 'package:app_animations/src/motion/app_motion_curve.dart';
import 'package:app_animations/src/motion/app_motion_duration.dart';
import 'package:flutter/widgets.dart';

/// Wraps one list/grid item with a bounded, staggered entrance — the item
/// at [index] fades/slides in [step] * min(index, [maxAnimatedIndex]) after
/// its siblings, so items are never staggered by an unbounded amount for a
/// long list.
///
/// **Runs once on first appearance only.** The decision to animate (or not)
/// is made on this widget's very first `build()` and cached in its `State`
/// for the widget's lifetime — a later rebuild of the same list item (e.g.
/// a `BlocBuilder` re-evaluating on state that isn't this item's data)
/// returns [child] unwrapped, so the entrance motion never replays. Give
/// each item a stable `key` (e.g. from its id) so list reordering/rebuilds
/// map to the same `State` instead of recreating it.
///
/// Items beyond [maxAnimatedIndex] render immediately with no entrance
/// motion at all — for a long list, animating every row (including
/// off-screen ones a `ListView` hasn't even laid out yet) wastes work for
/// no visible benefit; only the items a user actually sees appear
/// staggered.
class AppListEntrance extends StatefulWidget {
  const AppListEntrance({
    required this.index,
    required this.child,
    super.key,
    this.maxAnimatedIndex = 12,
    this.step = const Duration(milliseconds: 40),
    this.duration = AppMotionDuration.normal,
    this.curve = AppMotionCurve.decelerated,
    this.distance = 16,
  });

  /// This item's position in the list/grid.
  final int index;

  final Widget child;

  /// Items at or beyond this index render with no entrance motion.
  final int maxAnimatedIndex;

  /// Delay added per index, up to [maxAnimatedIndex].
  final Duration step;

  final Duration duration;
  final Curve curve;
  final double distance;

  @override
  State<AppListEntrance> createState() => _AppListEntranceState();
}

class _AppListEntranceState extends State<AppListEntrance> {
  bool _played = false;

  @override
  Widget build(BuildContext context) {
    final shouldAnimate =
        !_played &&
        widget.index < widget.maxAnimatedIndex &&
        !AppMotion.reduceMotionOf(context);
    _played = true;

    if (!shouldAnimate) return widget.child;

    final cappedIndex = widget.index.clamp(0, widget.maxAnimatedIndex);
    return widget.child.appFadeSlideUp(
      context,
      duration: widget.duration,
      curve: widget.curve,
      distance: widget.distance,
      delay: widget.step * cappedIndex,
    );
  }
}
