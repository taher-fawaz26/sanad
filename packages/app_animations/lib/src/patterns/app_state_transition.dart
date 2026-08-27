import 'package:app_animations/src/motion/app_motion_curve.dart';
import 'package:app_animations/src/motion/app_motion_duration.dart';
import 'package:flutter/widgets.dart';

/// Cross-fades between the widget built for successive values of [value]
/// (e.g. a `RequestStatus`: loading → success → error) without rebuilding
/// the whole screen — only the small subtree [builder] returns is swapped.
///
/// [value] must have value equality (an enum, or an `Equatable` state) —
/// it's used as the [AnimatedSwitcher] child's key, so a value that compares
/// equal to the previous one does not trigger a transition.
///
/// This is functional motion (it communicates a state change), so it is not
/// gated by reduced motion — only its duration matters there, and
/// [AppMotionDuration.normal] is already short enough not to be disruptive.
class AppStateTransition<T> extends StatelessWidget {
  const AppStateTransition({
    required this.value,
    required this.builder,
    super.key,
    this.duration = AppMotionDuration.normal,
    this.curve = AppMotionCurve.standard,
  });

  final T value;
  final Widget Function(BuildContext context, T value) builder;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      child: KeyedSubtree(
        key: ValueKey(value),
        child: builder(context, value),
      ),
    );
  }
}
