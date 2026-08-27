import 'package:app_animations/src/motion/app_motion.dart';
import 'package:app_animations/src/motion/app_motion_curve.dart';
import 'package:app_animations/src/motion/app_motion_duration.dart';
import 'package:flutter/widgets.dart';

/// Lightweight tap-scale feedback for a custom tappable widget (design
/// components with their own tap feedback — `AppButton`'s `InkWell`,
/// Material ripples, etc. — should keep using those instead).
///
/// Built on [AnimatedScale] (an implicit animation) rather than a manual
/// `AnimationController` — no controller to create or dispose, no ticker to
/// leak. Scale-down-on-press is gated by reduced motion (a transform,
/// unlike a plain opacity fade); the tap itself always fires regardless.
class AppButtonFeedback extends StatefulWidget {
  const AppButtonFeedback({
    required this.child,
    super.key,
    this.onTap,
    this.pressedScale = 0.96,
    this.duration = AppMotionDuration.fast,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Scale applied while pressed.
  final double pressedScale;
  final Duration duration;

  @override
  State<AppButtonFeedback> createState() => _AppButtonFeedbackState();
}

class _AppButtonFeedbackState extends State<AppButtonFeedback> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final reduceMotion = AppMotion.reduceMotionOf(context);
    final scale = (enabled && _pressed && !reduceMotion)
        ? widget.pressedScale
        : 1.0;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      child: AnimatedScale(
        scale: scale,
        duration: widget.duration,
        curve: AppMotionCurve.standard,
        child: widget.child,
      ),
    );
  }
}
