import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/presentation/models/radius_overlay_style.dart';

class AnimatedCircleOverlay extends StatelessWidget {
  const AnimatedCircleOverlay({
    required this.center,
    required this.radiusKm,
    required this.strokeColor,
    required this.builder,
    this.style = const RadiusOverlayStyle(),
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    super.key,
  });

  final LatLng? center;
  final double radiusKm;
  final Color strokeColor;
  final RadiusOverlayStyle style;
  final Duration duration;
  final Curve curve;
  final Widget Function(Set<Circle> circles) builder;

  static const _metersPerKm = 1000.0;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: radiusKm),
      duration: duration,
      curve: curve,
      builder: (context, animatedRadius, _) {
        final c = center;
        if (c == null) return builder(const {});

        final circles = {
          Circle(
            circleId: CircleId(style.circleId),
            center: c,
            radius: animatedRadius * _metersPerKm,
            strokeColor: strokeColor,
            strokeWidth: style.strokeWidth,
            fillColor: style.fillAlpha > 0
                ? strokeColor.withValues(alpha: style.fillAlpha)
                : const Color(0x00000000),
          ),
        };
        return builder(circles);
      },
    );
  }
}
