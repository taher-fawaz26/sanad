/// OTP timer constants.
///
/// This is deliberately NOT a motion/animation token set — for
/// duration/curve tokens use `AppMotionDuration`/`AppMotionCurve`
/// (`package:app_animations`) instead. These two values are `Timer.periodic`
/// polling intervals for the OTP countdown label, not animation durations;
/// they stay here (rather than in `AppMotionDuration`) because nothing about
/// them is motion — no `Animation`/`AnimationController`/implicit
/// `Animated*` widget consumes them.
abstract final class AppDurations {
  AppDurations._();

  /// OTP resend countdown tick.
  static const Duration otpTimerTick = Duration(seconds: 1);

  /// OTP resend cooldown.
  static const Duration otpResendCooldown = Duration(seconds: 60);
}
