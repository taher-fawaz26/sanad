import 'package:app_animations/app_animations.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/gestures.dart';

/// Maps a vertical drag on a sheet's handle to its route `AnimationController`
/// (which runs 0 = fully dismissed → 1 = fully presented at the largest snap
/// fraction), then resolves the gesture to either a dismiss, or a snap to the
/// nearest [snapFractions] entry.
///
/// Pure gesture math — no widgets, no BuildContext.
class SheetDragController {
  SheetDragController({
    required this.controller,
    required this.snapFractions,
    required this.onDismiss,
    this.dismissVelocityThreshold = 700,
    this.dismissExtentThreshold = 0.5,
  }) : assert(snapFractions.isNotEmpty, 'snapFractions must not be empty');

  final AnimationController controller;

  /// Ascending screen-height fractions, matching `SheetRouteSettings`.
  final List<double> snapFractions;

  /// Called when a drag should dismiss the sheet instead of snapping.
  final VoidCallback onDismiss;

  /// Downward fling velocity (logical px/s) past which the sheet dismisses
  /// regardless of how far it was dragged.
  final double dismissVelocityThreshold;

  /// Fraction of the smallest snap point below which a slow drag-release
  /// dismisses rather than snapping back.
  final double dismissExtentThreshold;

  double get _fullExtent => snapFractions.last;

  void onDragUpdate(DragUpdateDetails details, double screenHeight) {
    if (screenHeight <= 0) return;
    final delta = details.primaryDelta ?? 0;
    final deltaFraction = delta / screenHeight;
    final next = (controller.value - deltaFraction).clamp(0.0, 1.0);
    controller.value = next;
  }

  void onDragEnd(DragEndDetails details, double screenHeight) {
    final velocity = details.primaryVelocity ?? 0;

    if (velocity > dismissVelocityThreshold) {
      onDismiss();
      return;
    }
    if (velocity < -dismissVelocityThreshold) {
      _animateTo(_fullExtent);
      return;
    }

    final currentExtent = controller.value * _fullExtent;
    if (currentExtent < snapFractions.first * dismissExtentThreshold) {
      onDismiss();
      return;
    }

    final nearest = snapFractions.reduce(
      (a, b) => (currentExtent - a).abs() <= (currentExtent - b).abs() ? a : b,
    );
    _animateTo(nearest);
  }

  void _animateTo(double extentFraction) {
    final target = _fullExtent == 0 ? 0.0 : extentFraction / _fullExtent;
    controller.animateTo(
      target.clamp(0.0, 1.0),
      curve: AppMotionCurve.decelerated,
    );
  }
}
