import 'dart:math' as math;

import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/loading_indicator_tokens.dart';
import 'package:flutter/material.dart';

// ─── AppLoadingIndicator ─────────────────────────────────────────────────────

/// Sanad Design System loading indicator — Figma `Loader` (`53:2061`).
///
/// Renders a gradient ring that fades from a solid leading tip (marked by a
/// small dot) around to fully transparent, continuously rotating. All
/// colours are resolved from `AppColors` so the widget adapts automatically
/// to light / dark theme without any extra configuration.
///
/// ### Basic usage
/// ```dart
/// const AppLoadingIndicator()
/// ```
///
/// ### Custom size
/// ```dart
/// AppLoadingIndicator(size: 24, strokeWidth: 3.5)
/// ```
///
/// ### Custom colour
/// ```dart
/// AppLoadingIndicator(color: Colors.white)
/// ```
///
/// ### Performance notes
/// - Wrapped in `RepaintBoundary` — the spinner repaints independently of the
///   surrounding widget tree.
/// - `LoadingIndicatorPainter` listens directly to the rotation controller
///   via its `repaint` listenable, so **no widget rebuilds occur during
///   animation** — only the `RenderCustomPaint` is dirtied each frame.
/// - Respects `MediaQuery.disableAnimations` for accessibility.
///
/// See also:
///  * [LoadingIndicatorTokens], which defines default values.
///  * [LoadingIndicatorPainter], which handles all rendering.
class AppLoadingIndicator extends StatefulWidget {
  const AppLoadingIndicator({
    super.key,
    this.size,
    this.strokeWidth,
    this.color,
    this.duration,
    this.semanticsLabel,
  });

  /// Outer diameter of the spinner.
  /// Defaults to [LoadingIndicatorTokens.defaultSize] (40 dp).
  final double? size;

  /// Stroke width of the gradient ring.
  /// Defaults to [LoadingIndicatorTokens.defaultStrokeWidth] (6 dp).
  final double? strokeWidth;

  /// Colour of the ring's solid leading tip and dot — fades to transparent
  /// around the rest of the ring.
  /// Defaults to `AppColors.primary`.
  final Color? color;

  /// Duration of one full 360° rotation.
  /// Defaults to [LoadingIndicatorTokens.rotationDuration] (1 333 ms).
  final Duration? duration;

  /// Semantic label announced by screen readers.
  /// Defaults to `'Loading'`.
  final String? semanticsLabel;

  @override
  State<AppLoadingIndicator> createState() => _AppLoadingIndicatorState();
}

class _AppLoadingIndicatorState extends State<AppLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: widget.duration ?? LoadingIndicatorTokens.rotationDuration,
    )..repeat();
  }

  @override
  void didUpdateWidget(AppLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _rotationController.duration =
          widget.duration ?? LoadingIndicatorTokens.rotationDuration;
      if (_rotationController.isAnimating) _rotationController.repeat();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>();
    final colorScheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final arcColor =
        widget.color ??
        (appColors != null
            ? LoadingIndicatorTokens.resolveColor(appColors)
            : colorScheme.primary);

    final size = widget.size ?? LoadingIndicatorTokens.defaultSize;
    final strokeWidth =
        widget.strokeWidth ?? LoadingIndicatorTokens.defaultStrokeWidth;

    // When system animations are disabled, render a fixed rotation angle to
    // indicate loading state without motion.
    final rotationAnimation = reduceMotion
        ? const AlwaysStoppedAnimation<double>(0)
        : _rotationController;

    final painter = LoadingIndicatorPainter._(
      rotationAnimation: rotationAnimation,
      arcColor: arcColor,
      strokeWidth: strokeWidth,
    );

    return Semantics(
      label: widget.semanticsLabel ?? 'Loading',
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(painter: painter),
        ),
      ),
    );
  }
}

// ─── LoadingIndicatorPainter ─────────────────────────────────────────────────

/// `CustomPainter` for [AppLoadingIndicator].
///
/// Renders a full-circle [SweepGradient] ring — opaque at the leading tip,
/// fading to fully transparent around the rest of the circle — plus a small
/// solid dot marking the leading tip. The whole shape rotates continuously.
///
/// The painter listens directly to the rotation controller (via its
/// `repaint` listenable), so repainting never triggers a widget rebuild —
/// only the `RenderCustomPaint` layer is dirtied.
class LoadingIndicatorPainter extends CustomPainter {
  LoadingIndicatorPainter._({
    required this.rotationAnimation,
    required this.arcColor,
    required this.strokeWidth,
  }) : super(repaint: rotationAnimation);

  final Animation<double> rotationAnimation;
  final Color arcColor;
  final double strokeWidth;

  static const double _twoPi = math.pi * 2;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final radius = (side - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Leading tip starts at the top and sweeps clockwise as it rotates.
    final headAngle = -math.pi / 2 + rotationAnimation.value * _twoPi;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = SweepGradient(
          startAngle: headAngle,
          endAngle: headAngle + _twoPi,
          colors: [arcColor, arcColor.withValues(alpha: 0)],
        ).createShader(rect)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke,
    );

    final dotRadius = strokeWidth / 2;
    final dotCenter = Offset(
      center.dx + radius * math.cos(headAngle),
      center.dy + radius * math.sin(headAngle),
    );
    canvas.drawCircle(dotCenter, dotRadius, Paint()..color = arcColor);
  }

  /// Returns `true` only when a structural property (colour or stroke width)
  /// changes. Animation-driven repaints are handled by the `repaint`
  /// listenable passed to `super`, so animation ticks never trigger this
  /// check.
  @override
  bool shouldRepaint(LoadingIndicatorPainter oldDelegate) =>
      oldDelegate.arcColor != arcColor ||
      oldDelegate.strokeWidth != strokeWidth;

  @override
  bool shouldRebuildSemantics(LoadingIndicatorPainter oldDelegate) => false;
}
