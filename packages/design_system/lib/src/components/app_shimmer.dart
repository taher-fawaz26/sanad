import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/utils/constants/app_durations.dart';
import 'package:flutter/material.dart';

/// Animated shimmer effect that sweeps a gradient highlight across [child].
///
/// Wrap any placeholder skeleton layout with this widget to add the standard
/// Sanad loading animation. The gradient cycles every [AppDurations.shimmer]
/// (1200 ms).
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
      duration: AppDurations.shimmer,
    )..repeat();
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
