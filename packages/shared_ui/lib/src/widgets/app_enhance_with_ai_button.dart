import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Figma `Enhance with AI` pill button (`3233:17332`).
///
/// Design reference: `lib/src/widgets/enhance_with_ai.svg`.
///
/// The border is a rainbow conic gradient that continuously flows around the
/// outline. `flutter_svg` cannot render the CSS `conic-gradient` inside the
/// SVG's `<foreignObject>`, so the gradient is painted via [CustomPainter].
class AppEnhanceWithAiButton extends StatefulWidget {
  const AppEnhanceWithAiButton({
    super.key,
    required this.label,
    this.onTap,
    this.animate = true,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onTap;

  /// Whether the rainbow border flows around the outline.
  final bool animate;

  /// When `true`, disables tap and shows a loading indicator in place of the
  /// icon/label — mirrors [AppButton]'s `isLoading` idiom.
  final bool isLoading;

  static const _width = 160.0;
  static const _height = 41.0;
  static const _radius = 20.5;
  static const _borderWidth = 2.0;

  // #26A68C — the sparkle color from the SVG
  static const _sparkleColor = Color(0xFF26A68C);

  /// One full revolution — calm, premium pace.
  static const _flowDuration = Duration(milliseconds: 5200);

  @override
  State<AppEnhanceWithAiButton> createState() => _AppEnhanceWithAiButtonState();
}

class _AppEnhanceWithAiButtonState extends State<AppEnhanceWithAiButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppEnhanceWithAiButton._flowDuration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant AppEnhanceWithAiButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    final shouldAnimate =
        widget.animate && !MediaQuery.disableAnimationsOf(context);
    if (shouldAnimate) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
      return;
    }
    if (_controller.isAnimating) {
      _controller.stop();
    }
    _controller.value = 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TickerMode automatically pauses the controller's ticker when false
    // (e.g. off-screen in scrollables). disableAnimations stops + resets.
    final animateBorder =
        widget.animate && !MediaQuery.disableAnimationsOf(context);

    const radius = BorderRadius.all(
      Radius.circular(AppEnhanceWithAiButton._radius),
    );

    final enabled = widget.onTap != null && !widget.isLoading;

    return SizedBox(
      width: AppEnhanceWithAiButton._width,
      height: AppEnhanceWithAiButton._height,
      child: Material(
        color: Colors.white,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? widget.onTap : null,
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: widget.isLoading
                    ? const Center(
                        child: AppLoadingIndicator(size: 16),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: AppEnhanceWithAiButton._sparkleColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
              ),
              // Isolated paint layer — animation only invalidates this boundary.
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _EnhanceBorderPainter(
                        animation: _controller,
                        animate: animateBorder,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints the flowing rainbow outline.
///
/// Bound to [animation] via [CustomPainter.repaint] so only this layer
/// invalidates — no widget rebuilds or layout passes during the flow.
class _EnhanceBorderPainter extends CustomPainter {
  _EnhanceBorderPainter({
    required this.animation,
    required this.animate,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final bool animate;

  // Original SVG key colors, with intermediate samples for smoother blending
  // between harsh jumps (especially white → green → yellow → red → blue).
  static const _colors = [
    Color(0xFF0B8FFF), // blue
    Color(0xFF4AA6FF),
    Color(0xFF98C6FF), // light blue
    Color(0xFFCBE3FF),
    Color(0xFFFFFFFF), // white
    Color(0xFFFFFFFF), // white hold
    Color(0xFFB8E8D0),
    Color(0xFF02B35B), // green
    Color(0xFF7FCA2E),
    Color(0xFFFFCE00), // yellow
    Color(0xFFFF7A18),
    Color(0xFFFF3C2B), // red
    Color(0xFF8A5F95),
    Color(0xFF0B8FFF), // blue (seamless loop)
  ];

  // Stops remapped from the SVG degrees, with easing between clusters so the
  // spectrum reads as continuous energy rather than hard bands.
  static const _stops = [
    0.0, // 0°
    0.14,
    0.311, // ~112°
    0.47,
    0.635, // ~229°
    0.777, // ~280°
    0.84,
    0.898, // ~323°
    0.912,
    0.925, // ~333°
    0.946,
    0.968, // ~349°
    0.985,
    1.0, // 360°
  ];

  final Paint _borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = AppEnhanceWithAiButton._borderWidth
    ..isAntiAlias = true;

  Size? _cachedSize;
  RRect? _borderRRect;
  Rect? _shaderRect;

  void _ensureGeometry(Size size) {
    if (_cachedSize == size && _borderRRect != null) {
      return;
    }
    _cachedSize = size;
    const inset = AppEnhanceWithAiButton._borderWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - AppEnhanceWithAiButton._borderWidth,
      size.height - AppEnhanceWithAiButton._borderWidth,
    );
    _borderRRect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(rect.height / 2),
    );
    _shaderRect = Offset.zero & size;
  }

  @override
  void paint(Canvas canvas, Size size) {
    _ensureGeometry(size);

    // Linear angular travel — required for a perfectly seamless loop.
    final angle = animate ? animation.value * 2 * math.pi : 0.0;

    _borderPaint.shader = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      colors: _colors,
      stops: _stops,
      transform: GradientRotation(angle),
    ).createShader(_shaderRect!);

    canvas.drawRRect(_borderRRect!, _borderPaint);
  }

  @override
  bool shouldRepaint(covariant _EnhanceBorderPainter oldDelegate) {
    return oldDelegate.animate != animate || oldDelegate.animation != animation;
  }
}
