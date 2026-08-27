import 'package:app_animations/app_animations.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:flutter/material.dart';

/// Animated shimmer effect that sweeps a gradient highlight across [child].
///
/// Wrap any placeholder skeleton layout with this widget to add the standard
/// Sanad loading animation. The gradient cycles every
/// [AppMotionDuration.shimmer] (1200 ms).
///
/// **Documented exception — kept as a bespoke `AnimationController` +
/// `ShaderMask` rather than `app_animations`' generic shimmer effect.**
/// `ShaderMask` with `BlendMode.srcATop` *replaces* the child's own pixel
/// colors with the traveling `[base, highlight, base]` gradient — the child
/// widgets ([ShimmerBox]/[ShimmerCircle]) render a fixed `onBackground`
/// fill, but what's actually visible is always the light `disabled`/
/// `surface` sweep, never that fill color. `flutter_animate`'s built-in
/// shimmer effect overlays a highlight on top of the child's existing paint
/// instead of replacing it — swapping to it would let the child's own dark
/// fill show through between sweeps, a visible regression on every skeleton
/// screen in both apps. Still fully integrated with the shared motion
/// vocabulary: duration from [AppMotionDuration.shimmer], reduced motion
/// from [AppMotion.reduceMotionOf] (freezes the sweep; the skeleton shape
/// itself still communicates "loading" without the decorative motion).
class AppShimmer extends StatefulWidget {
  const AppShimmer({required this.child, super.key});

  final Widget child;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotionDuration.shimmer,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced-motion is read from an InheritedWidget (MediaQuery), so this
    // must happen here rather than initState — didChangeDependencies is
    // guaranteed to run once before the first build, so the sweep starts (or
    // doesn't) correctly from frame one either way.
    _syncAnimating();
  }

  void _syncAnimating() {
    if (AppMotion.reduceMotionOf(context)) {
      if (_controller.isAnimating) _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final base = colors.disabled;
    final highlight = colors.surface;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final slide = _controller.value * 2 - 0.5;
            return LinearGradient(
              colors: [base, highlight, base],
              stops: [
                (slide - 0.3).clamp(0.0, 1.0),
                slide.clamp(0.0, 1.0),
                (slide + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Rectangular shimmer placeholder.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    required this.height,
    super.key,
    this.width,
    this.borderRadius = 4,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.appColors.onBackground,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Circular shimmer placeholder.
class ShimmerCircle extends StatelessWidget {
  const ShimmerCircle({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.appColors.onBackground,
        shape: BoxShape.circle,
      ),
    );
  }
}
