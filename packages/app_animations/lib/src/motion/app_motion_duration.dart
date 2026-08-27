/// The single source of truth for animation/motion durations across the
/// monorepo.
///
/// Every value here was chosen to match a duration already in live use
/// somewhere in the app (never invented) — see the doc on each constant for
/// where it comes from. Keep this list small and semantic; do not add a
/// bespoke one-off duration here just because it exists somewhere — a
/// duration used in exactly one place (e.g. a splash sequence, a specific
/// button's flourish) belongs as a local constant next to its widget, not
/// in the shared vocabulary.
abstract final class AppMotionDuration {
  AppMotionDuration._();

  /// No animation — used to short-circuit a transition under reduced motion.
  static const Duration instant = Duration.zero;

  /// Small, snappy state changes (e.g. an icon swap).
  static const Duration fast = Duration(milliseconds: 150);

  /// Micro UI-state transitions — a focused search field expanding, a
  /// segmented-control thumb sliding, a switch toggling.
  static const Duration quick = Duration(milliseconds: 200);

  /// The default for most transitions — sheet enter, generic component
  /// motion.
  static const Duration normal = Duration(milliseconds: 300);

  /// Deliberately slower, attention-drawing motion.
  static const Duration emphasis = Duration(milliseconds: 500);

  /// Route/page transition duration.
  static const Duration pageTransition = Duration(milliseconds: 350);

  /// One full shimmer sweep.
  static const Duration shimmer = Duration(milliseconds: 1200);
}
