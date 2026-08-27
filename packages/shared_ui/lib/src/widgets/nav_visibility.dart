import 'package:app_animations/app_animations.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_ui/src/widgets/nav_visibility_controller.dart';

/// Animates a persistent bottom navigation bar in/out of view following
/// [controller], collapsing its allocated height to zero when hidden (rather
/// than merely fading it out in place) so the body above reclaims the space —
/// matching how a `Scaffold.bottomNavigationBar` slot should behave.
///
/// [preferredHeight] is the bar's fully-visible height. It is applied
/// explicitly (via a fixed-height child) rather than measured, since some nav
/// bar implementations don't report a usable intrinsic height.
class NavVisibility extends StatelessWidget {
  /// Creates the animated visibility wrapper.
  const NavVisibility({
    required this.controller,
    required this.preferredHeight,
    required this.child,
    this.duration = const Duration(milliseconds: 220),
    super.key,
  });

  /// Drives the show/hide state.
  final NavVisibilityController controller;

  /// The bar's fully-visible height.
  final double preferredHeight;

  /// The bottom navigation bar widget.
  final Widget child;

  /// Duration of the show/hide transition. `220ms` is a bespoke, one-off
  /// tuning for this specific collapse — deliberately not
  /// [AppMotionDuration.quick] (200ms); kept as a local default (still
  /// caller-overridable) rather than promoted to the shared vocabulary.
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(end: controller.visible ? 1 : 0),
          duration: duration,
          curve: AppMotionCurve.standard,
          builder: (context, factor, child) {
            return Align(
              alignment: Alignment.topCenter,
              heightFactor: factor,
              child: SizedBox(
                height: preferredHeight,
                child: Opacity(opacity: factor, child: child),
              ),
            );
          },
          child: child,
        );
      },
      child: child,
    );
  }
}
