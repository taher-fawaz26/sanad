import 'dart:math' as math;

import 'package:app_animations/src/motion/app_motion.dart';
import 'package:flutter/widgets.dart';

/// A slow, wandering glow behind [child] — an ambient backdrop, not a loading
/// state or a piece of content.
///
/// Built from gradients rather than a blurred shape: a `RadialGradient`
/// already fades to nothing with no hard edge and no `MaskFilter`, so the
/// "soft, no visible seam" look this is asked for comes at essentially zero
/// extra paint cost — cheaper than blurring a shape every frame, which is
/// the part a slow full-screen background cannot afford to get wrong.
///
/// ## Why this is not a `Timer` and not a page-owned `AnimationController`
///
/// The animation lives entirely inside this widget's own
/// `SingleTickerProviderStateMixin`; nothing above it drives or even knows
/// about the ticker. The glow's position is `sin`/`cos` of the controller's
/// value at two different frequencies (a small Lissajous drift rather than a
/// perfect circle, which is what keeps the motion reading as "ambient" rather
/// than "orbiting") — a periodic function of a value that itself repeats
/// `0→1` is continuous at the seam by construction, so `..repeat()` loops
/// with no jump to design around.
///
/// ## Isolation
///
/// The animated painter sits in its own [RepaintBoundary], below [child] in
/// a [Stack] — a tick here repaints only this backdrop, never whatever
/// content is layered on top (a message list, a composer, anything driven by
/// its own Bloc). No Bloc, no business state, is read here at all.
class AppAmbientGradient extends StatefulWidget {
  /// Creates the backdrop. [color] is the glow's hue — pass a low-alpha
  /// color already, or let [intensity] scale it down here.
  const AppAmbientGradient({
    required this.color,
    super.key,
    this.intensity = 0.16,
    this.child,
  });

  /// The glow's base hue. Softened by [intensity]; this widget never
  /// hardcodes a color of its own.
  final Color color;

  /// Peak alpha of the glow at the strongest point of its drift, 0..1. Low by
  /// design — this is a backdrop, not a decoration meant to be noticed.
  final double intensity;

  /// Rendered above the animated backdrop, unaffected by its repaints.
  final Widget? child;

  @override
  State<AppAmbientGradient> createState() => _AppAmbientGradientState();
}

class _AppAmbientGradientState extends State<AppAmbientGradient>
    with SingleTickerProviderStateMixin {
  /// One full drift cycle. Long and prime-ish relative to the Y frequency
  /// below, so the path does not visibly retrace itself lap to lap.
  static const Duration _period = Duration(seconds: 22);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Created but not started: `AppMotion.reduceMotionOf` reads `MediaQuery`,
    // which `initState` runs too early to depend on safely. `value` defaults
    // to 0, so if `didChangeDependencies` below decides not to animate, the
    // glow still paints once at the cycle's start position — a still glow is
    // still a glow, reduced motion means no drift, not no backdrop.
    _controller = AnimationController(vsync: this, duration: _period);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = AppMotion.reduceMotionOf(context);
    if (reduceMotion && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!reduceMotion && !_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            key: ambientGlowPainterKey,
            painter: _AmbientGlowPainter(
              t: _controller.value,
              color: widget.color,
              intensity: widget.intensity,
            ),
          ),
        ),
      ),
      if (widget.child != null) widget.child!,
    ],
  );
}

/// Identifies the animated backdrop's own `CustomPaint` for tests — a plain
/// `find.byType(CustomPaint)` is not reliable here, since `Scaffold`/
/// `Material` mount `CustomPaint`s of their own.
@visibleForTesting
const Key ambientGlowPainterKey = ValueKey('app_ambient_gradient_painter');

class _AmbientGlowPainter extends CustomPainter {
  const _AmbientGlowPainter({
    required this.t,
    required this.color,
    required this.intensity,
  });

  final double t;
  final Color color;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final angle = t * 2 * math.pi;
    // Two glows, out of phase, each drifting on its own Lissajous path within
    // the lower two-thirds of the area — matching the source design's own
    // gradient, which concentrates green toward the bottom of the frame
    // rather than spreading it evenly.
    _paintGlow(
      canvas,
      size,
      center: Offset(
        size.width * (0.5 + 0.22 * math.sin(angle)),
        size.height * (0.68 + 0.16 * math.cos(angle * 1.3)),
      ),
      radius: size.longestSide * 0.55,
      alpha: intensity,
    );
    _paintGlow(
      canvas,
      size,
      center: Offset(
        size.width * (0.5 + 0.3 * math.cos(angle * 0.8 + math.pi / 3)),
        size.height * (0.85 + 0.1 * math.sin(angle * 1.1)),
      ),
      radius: size.longestSide * 0.4,
      alpha: intensity * 0.7,
    );
  }

  void _paintGlow(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radius,
    required double alpha,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: alpha),
          color.withValues(alpha: alpha * 0.35),
          color.withValues(alpha: 0),
        ],
        stops: const [0, 0.5, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_AmbientGlowPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.color != color ||
      oldDelegate.intensity != intensity;
}
