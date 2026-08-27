/// Network-layer timing constants.
///
/// This is deliberately NOT a motion/animation token set — `core` must stay
/// UI/asset-free (see `dep_rules.yaml` `forbidden_edges`), so it cannot
/// depend on `app_animations`. Any duration that gates an `Animation`, an
/// implicit `Animated*` widget, or a transition belongs in
/// `AppMotionDuration` (package:app_animations) instead, not here.
///
/// This class previously also held OTP timer/splash/feature-UI-transition
/// constants (`otpTimerTick`, `otpCooldown`, `splashHold`,
/// `captureStepDotTransition`, etc.) — all had zero live consumers (the
/// splash page, OTP flow, and every named feature actually source their
/// timings from `design_system`'s `AppDurations` or their own local
/// constants) and were removed rather than kept as dead, duplicate-named
/// weight alongside the real `AppDurations` in `design_system`.
abstract final class AppDurations {
  AppDurations._();

  /// Base backoff delay before a timed-out request is retried.
  static const Duration dioRetryBaseDelay = Duration(milliseconds: 400);
}
