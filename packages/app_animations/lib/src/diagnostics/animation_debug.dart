import 'package:flutter/foundation.dart';

/// Debug-only animation diagnostics. All calls are no-ops in release builds
/// ([kReleaseMode]) — safe to leave call sites in place.
abstract final class AnimationDebug {
  AnimationDebug._();

  /// Flip on (e.g. from a debug menu) to log every rebuild reported via
  /// [logRebuild] — use to catch an animation driving more widget rebuilds
  /// than intended. The performance rule this checks: prefer
  /// `AnimatedBuilder`/`ListenableBuilder`/`CustomPainter.repaint` scoping
  /// (rebuilds a small subtree or repaints a single layer) over an
  /// animation that forces a large ancestor to rebuild every tick.
  static bool verboseRebuildLogging = false;

  /// Logs a rebuild under [label] when [verboseRebuildLogging] is on.
  /// No-ops in release builds and when logging is off.
  static void logRebuild(String label) {
    if (kReleaseMode || !verboseRebuildLogging) return;
    debugPrint('[app_animations] rebuild: $label');
  }
}
