import 'dart:ui';

import 'package:flutter/widgets.dart';

/// Applies a backdrop blur to [child] that grows from `0` to [maxSigma] as
/// collapse progress `t` moves from `1.0` (expanded) to `0.0` (collapsed) —
/// e.g. for a nav-bar surface that blurs in behind content once scrolled.
///
/// Generic scroll-effect utility — not tied to any specific header or page.
class BlurEffect extends StatelessWidget {
  const BlurEffect({
    required this.t,
    required this.child,
    super.key,
    this.maxSigma = 12,
  });

  /// Collapse progress: `1.0` fully expanded, `0.0` fully collapsed.
  final double t;

  final double maxSigma;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sigma = maxSigma * (1 - t.clamp(0.0, 1.0));
    if (sigma <= 0) {
      return child;
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: child,
      ),
    );
  }
}
