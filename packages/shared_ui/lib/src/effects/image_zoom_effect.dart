import 'package:flutter/widgets.dart';

/// Scales [child] up in response to overscroll, producing the "zoom in on
/// pull-down" effect common on hero/cover images.
///
/// [overscroll] should be the positive overscroll distance — pass `0` when
/// not overscrolling.
///
/// Generic scroll-effect utility — not tied to any specific header or page.
class ImageZoomEffect extends StatelessWidget {
  const ImageZoomEffect({
    required this.overscroll,
    required this.child,
    super.key,
    this.maxOverscroll = 100,
    this.maxScale = 1.3,
  });

  final double overscroll;
  final double maxOverscroll;
  final double maxScale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final progress = maxOverscroll <= 0
        ? 0.0
        : (overscroll.clamp(0.0, maxOverscroll) / maxOverscroll);
    final scale = 1 + (maxScale - 1) * progress;

    return Transform.scale(scale: scale, child: child);
  }
}
