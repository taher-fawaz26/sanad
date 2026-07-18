import 'dart:math' as math;

import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/loading_indicator_tokens.dart';
import 'package:flutter/material.dart';

// ─── AppLoadingIndicator ─────────────────────────────────────────────────────

/// Sanad Design System loading indicator.
///
/// Renders a circular spinner with an expanding and contracting arc that
/// rotates continuously. All colours are resolved from `AppColors` (or the
/// `ColorScheme` fallback) so the widget adapts automatically to light / dark
/// theme without any extra configuration.
///
/// ### Basic usage
/// ```dart
/// const AppLoadingIndicator()
/// ```
///
/// ### Custom size
/// ```dart
/// AppLoadingIndicator(size: 24, strokeWidth: 2.5)
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
/// - `LoadingIndicatorPainter` listens directly to the animation
///   controllers via its `repaint` listenable, so **no widget rebuilds occur
///   during animation** — only the `RenderCustomPaint` is dirtied each frame.
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
    this.backgroundColor,
    this.duration,
    this.semanticsLabel,
  });

  /// Outer diameter of the spinner.
  /// Defaults to [LoadingIndicatorTokens.defaultSize] (40 dp).
  final double? size;

  /// Stroke width of the arc and background ring.
  /// Defaults to [LoadingIndicatorTokens.defaultStrokeWidth] (4 dp).
  final double? strokeWidth;

  /// Colour of the rotating arc.
  /// Defaults to `AppColors.primary`.
  final Color? color;

  /// Colour of the static background ring.
  /// Defaults to `AppColors.controlFill`.
  final Color? backgroundColor;

  /// Duration of one full stroke expansion / contraction cycle.
  /// Defaults to [LoadingIndicatorTokens.animationDuration] (1 500 ms).
  final Duration? duration;

  /// Semantic label announced by screen readers.
  /// Defaults to `'Loading'`.
  final String? semanticsLabel;

  @override
  State<AppLoadingIndicator> createState() => _AppLoadingIndicatorState();
}

class _AppLoadingIndicatorState extends State<AppLoadingIndicator>
    with TickerProviderStateMixin {
  // Two independent controllers:
  //  _rotationController – drives the continuous clockwise rotation of the arc.
  //  _strokeController   – drives the expand / contract of the arc length.
  late final AnimationController _rotationController;
  late final AnimationController _strokeController;

  // Head: leading edge of the arc — accelerates in the first half of the cycle.
  late final Animation<double> _headAnimation;

  // Tail: trailing edge of the arc — follows in the second half.
  late final Animation<double> _tailAnimation;

  // Material-quality easing curve.
  static const Curve _kSwing = Cubic(0.4, 0, 0.2, 1);

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: LoadingIndicatorTokens.rotationDuration,
    )..repeat();

    _strokeController = AnimationController(
      vsync: this,
      duration: widget.duration ?? LoadingIndicatorTokens.animationDuration,
    )..repeat();

    _headAnimation = Tween<double>(begin: 0, end: 0.75).animate(
      CurvedAnimation(
        parent: _strokeController,
        curve: const Interval(
          LoadingIndicatorTokens.headStartInterval,
          LoadingIndicatorTokens.headEndInterval,
          curve: _kSwing,
        ),
      ),
    );

    _tailAnimation = Tween<double>(begin: 0, end: 0.75).animate(
      CurvedAnimation(
        parent: _strokeController,
        curve: const Interval(
          LoadingIndicatorTokens.tailStartInterval,
          LoadingIndicatorTokens.tailEndInterval,
          curve: _kSwing,
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(AppLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _strokeController.duration =
          widget.duration ?? LoadingIndicatorTokens.animationDuration;
      if (_strokeController.isAnimating) _strokeController.repeat();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _strokeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>();
    final colorScheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final arcColor = widget.color ??
        (appColors != null
            ? LoadingIndicatorTokens.resolveColor(appColors)
            : colorScheme.primary);

    final trackColor = widget.backgroundColor ??
        LoadingIndicatorTokens.resolveBackgroundColor(appColors, colorScheme);

    final size = widget.size ?? LoadingIndicatorTokens.defaultSize;
    final strokeWidth =
        widget.strokeWidth ?? LoadingIndicatorTokens.defaultStrokeWidth;

    // When system animations are disabled, render a fixed arc to indicate
    // loading state without motion.
    final painter = reduceMotion
        ? LoadingIndicatorPainter._(
            rotationAnimation: _rotationController,
            headAnimation: const AlwaysStoppedAnimation(0.25),
            tailAnimation: const AlwaysStoppedAnimation(0),
            arcColor: arcColor,
            trackColor: trackColor,
            strokeWidth: strokeWidth,
          )
        : LoadingIndicatorPainter._(
            rotationAnimation: _rotationController,
            headAnimation: _headAnimation,
            tailAnimation: _tailAnimation,
            arcColor: arcColor,
            trackColor: trackColor,
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
/// Renders a static background ring and a rotating arc whose length expands
/// and contracts. The painter listens directly to the animation controllers
/// (via its `repaint` listenable), so repainting never triggers a widget
/// rebuild — only the `RenderCustomPaint` layer is dirtied.
///
/// ### Arc geometry
/// - `startAngle` moves with the rotation controller and the arc head.
/// - `sweepAngle` is `(headValue − tailValue) × 270°`, clamped to a minimum
///   so the arc never fully disappears.
class LoadingIndicatorPainter extends CustomPainter {
  LoadingIndicatorPainter._({
    required this.rotationAnimation,
    required this.headAnimation,
    required this.tailAnimation,
    required this.arcColor,
    required this.trackColor,
    required this.strokeWidth,
  }) : super(
          repaint: Listenable.merge([rotationAnimation, headAnimation]),
        );

  final Animation<double> rotationAnimation;
  final Animation<double> headAnimation;
  final Animation<double> tailAnimation;
  final Color arcColor;
  final Color trackColor;
  final double strokeWidth;

  // ── Constants ──────────────────────────────────────────────────────────────

  static const double _twoPi = math.pi * 2;

  // Minimum visible sweep so Canvas.drawArc never receives 0 (a no-op).
  static const double _minSweep = 0.01;

  // Maximum sweep = sweepPiFactor × π = 1.5 × π ≈ 270°.
  static const double _sweepPi =
      LoadingIndicatorTokens.sweepPiFactor * math.pi;

  // ── Paint ──────────────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final radius = (side - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final head = headAnimation.value;
    final tail = tailAnimation.value;
    final rotation = rotationAnimation.value;

    // ── Background ring ────────────────────────────────────────────────────
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // ── Rotating arc ───────────────────────────────────────────────────────
    //
    // startAngle: arc head tracks the continuous rotation plus its own
    //   acceleration from the head animation.
    // sweepAngle: difference between head and tail positions (in radians),
    //   floored at _minSweep so the arc never fully disappears mid-cycle.
    final startAngle = -math.pi / 2 +
        rotation * _twoPi * LoadingIndicatorTokens.sweepPiFactor -
        head * _sweepPi;

    final sweepAngle = math.max(_minSweep, (head - tail) * _sweepPi);

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = arcColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  // ── Repaint logic ──────────────────────────────────────────────────────────

  /// Returns `true` only when a structural property (colour or stroke width)
  /// changes. Animation-driven repaints are handled by the `repaint` listenable
  /// passed to `super`, so animation ticks never trigger this check.
  @override
  bool shouldRepaint(LoadingIndicatorPainter oldDelegate) =>
      oldDelegate.arcColor != arcColor ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.strokeWidth != strokeWidth;

  @override
  bool shouldRebuildSemantics(LoadingIndicatorPainter oldDelegate) => false;
}
