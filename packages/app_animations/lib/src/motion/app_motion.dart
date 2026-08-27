import 'package:flutter/widgets.dart';

/// The single reduced-motion mechanism for the app.
///
/// Wraps the two platform accessibility signals that mean "avoid motion":
/// `MediaQuery.disableAnimations` (OS-level reduce-motion) and
/// `MediaQuery.accessibleNavigation` (a screen reader is active — swipe/tap
/// gestures replace visual motion cues for these users). Every decorative
/// effect, pattern, and the Lottie wrapper in this package consult this.
///
/// Functional motion that communicates a state change (a sheet opening, a
/// page navigating, a menu expanding, a loading spinner) is intentionally
/// NOT gated by this — only decorative/ambient motion is. See each widget's
/// own doc for which bucket it falls into.
abstract final class AppMotion {
  AppMotion._();

  /// Whether decorative motion should be suppressed or shortened for
  /// [context]'s current accessibility settings.
  static bool reduceMotionOf(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.disableAnimations || mediaQuery.accessibleNavigation;
  }
}
