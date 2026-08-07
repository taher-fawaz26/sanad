import 'package:flutter/widgets.dart';

/// Derives a `1.0` (expanded) → `0.0` (collapsed) progress value from a
/// [ScrollController]'s current offset.
///
/// A pure, stateless read of scroll position — call it inside an
/// [AnimatedBuilder] listening to [scrollController] rather than storing the
/// result in State, so it stays a derived layout value with no risk of
/// drifting out of sync with the actual scroll offset.
double scrollCollapseProgress({
  required ScrollController scrollController,
  required double collapseRange,
}) {
  if (!scrollController.hasClients || collapseRange <= 0) {
    return 1;
  }
  return (1 - scrollController.offset / collapseRange).clamp(0.0, 1.0);
}

/// Convenience accessor for [scrollCollapseProgress] on a [ScrollController].
extension ScrollCollapseProgress on ScrollController {
  /// See [scrollCollapseProgress].
  double collapseProgress(double collapseRange) => scrollCollapseProgress(
    scrollController: this,
    collapseRange: collapseRange,
  );
}
