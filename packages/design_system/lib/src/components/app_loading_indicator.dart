import 'dart:math' as math;

import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/loading_indicator_tokens.dart';
import 'package:flutter/material.dart';

// ─── AppLoadingIndicator ─────────────────────────────────────────────────────

/// Sanad Design System loading indicator — Figma `Loader` (`53:2061`).
///
/// Renders a 270° gradient arc that rotates continuously. The arc fades
/// from fully transparent at the tail through a light teal ramp to the
/// solid brand primary at the leading tip, capped with a rounded end.
///
/// All colours are resolved from `AppColors` so the widget adapts to
/// light / dark theme automatically.
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
/// ### Custom colour (derives light variant automatically)
/// ```dart
/// AppLoadingIndicator(color: Colors.white)
/// ```
///
/// ### Performance notes
/// - Wrapped in `RepaintBoundary` — the spinner repaints independently of the
///   surrounding widget tree.
/// - `LoadingIndicatorPainter` listens directly to the rotation controller
///   via its `repaint` listenable, so **no widget rebuilds occur during
///   animation** — only the `RenderCustomPaint` layer is dirtied each frame.
/// - Respects `MediaQuery.disableAnimations` for accessibility.
///
/// See also:
///  * [LoadingIndicatorTokens], which defines default values and stops.
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

  /// Stroke width of the gradient arc.
  /// Defaults to [LoadingIndicatorTokens.defaultStrokeWidth] (5 dp).
  final double? strokeWidth;

  /// Override the arc colour. When provided, the light gradient colour is
  /// derived automatically as 50 % opacity of this value.
  /// Defaults to `AppColors.primary`.
  final Color? color;

  /// Duration of one full 360° rotation.
  /// Defaults to [LoadingIndicatorTokens.rotationDuration] (1 100 ms).
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

    final Color arcColor;
    final Color lightArcColor;

    if (widget.color != null) {
      arcColor = widget.color!;
      lightArcColor = widget.color!.withValues(alpha: 0.5);
    } else if (appColors != null) {
      arcColor = LoadingIndicatorTokens.resolveColor(appColors);
      lightArcColor = LoadingIndicatorTokens.resolveLightColor(appColors);
    } else {
      arcColor = colorScheme.primary;
      lightArcColor = colorScheme.primary.withValues(alpha: 0.5);
    }

    final size = widget.size ?? LoadingIndicatorTokens.defaultSize;
    final strokeWidth =
        widget.strokeWidth ?? LoadingIndicatorTokens.defaultStrokeWidth;

    // When system animations are disabled, render a fixed position to
    // indicate loading state without motion.
    final rotationAnimation = reduceMotion
        ? const AlwaysStoppedAnimation<double>(0)
        : _rotationController;

    final painter = LoadingIndicatorPainter._(
      rotationAnimation: rotationAnimation,
      arcColor: arcColor,
      lightArcColor: lightArcColor,
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
/// Draws a 270° arc whose [SweepGradient] transitions:
///
/// ```plaintext
/// transparent → transparent → lightArcColor → arcColor
/// ```
///
/// The arc sweeps clockwise, with the solid leading tip at the head (end of
/// the sweep). `StrokeCap.round` creates a natural rounded end at the head
/// while the transparent tail end is invisible. The entire arc rotates every
/// frame via the [rotationAnimation] listenable — no widget rebuild occurs.
class LoadingIndicatorPainter extends CustomPainter {
  LoadingIndicatorPainter._({
    required this.rotationAnimation,
    required this.arcColor,
    required this.lightArcColor,
    required this.strokeWidth,
  }) : super(repaint: rotationAnimation);

  final Animation<double> rotationAnimation;
  final Color arcColor;
  final Color lightArcColor;
  final double strokeWidth;

  static const double _twoPi = math.pi * 2;

  // 270° arc — matches the iOS-style reference and the Figma design.
  static const double _sweepAngle =
      _twoPi * LoadingIndicatorTokens.sweepFraction;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final radius = (side - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Head starts at 12 o'clock (-π/2) and rotates clockwise each frame.
    final headAngle = -math.pi / 2 + rotationAnimation.value * _twoPi;
    final tailAngle = headAngle - _sweepAngle;

    canvas.drawArc(
      rect,
      tailAngle,
      _sweepAngle,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth
        ..shader = SweepGradient(
          startAngle: tailAngle,
          endAngle: headAngle,
          colors: [
            Colors.transparent, // tail — round cap here is invisible
            Colors.transparent,
            lightArcColor, // gradient ramp begins
            arcColor, // solid leading tip — round cap visible here
          ],
          stops: LoadingIndicatorTokens.gradientStops,
        ).createShader(rect),
    );
  }

  /// Returns `true` only when a structural property changes. Animation-driven
  /// repaints are handled by the `repaint` listenable passed to `super`, so
  /// animation ticks never trigger this check.
  @override
  bool shouldRepaint(LoadingIndicatorPainter oldDelegate) =>
      oldDelegate.arcColor != arcColor ||
      oldDelegate.lightArcColor != lightArcColor ||
      oldDelegate.strokeWidth != strokeWidth;

  @override
  bool shouldRebuildSemantics(LoadingIndicatorPainter oldDelegate) => false;
}
