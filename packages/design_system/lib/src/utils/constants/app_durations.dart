/// Design-system animation and timer durations.
abstract final class AppDurations {
  AppDurations._();

  static const Duration instant = Duration.zero;
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  /// OTP resend countdown tick — 1 second.
  static const Duration otpTimerTick = Duration(seconds: 1);

  /// OTP resend cooldown — 60 seconds.
  static const Duration otpResendCooldown = Duration(seconds: 60);

  static const Duration pageTransition = Duration(milliseconds: 350);
  static const Duration shimmer = Duration(milliseconds: 1200);

  /// Notch bottom bar slide / morph duration (Dribbble-tuned).
  static const Duration notchBar = Duration(milliseconds: 450);
}
