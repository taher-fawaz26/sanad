abstract final class AppDurations {
  AppDurations._();

  // ── OTP ───────────────────────────────────────────────────────────────────
  static const Duration otpTimerTick = Duration(seconds: 1);
  static const int otpCooldownSeconds = 30;
  static const Duration otpCooldown = Duration(seconds: otpCooldownSeconds);

  // ── Splash ────────────────────────────────────────────────────────────────
  static const Duration splashHold = Duration(milliseconds: 2500);
  static const Duration splashLogoAnimation = Duration(milliseconds: 850);
  static const Duration splashDotsCycle = Duration(milliseconds: 900);

  // ── Network / cache ───────────────────────────────────────────────────────
  static const Duration dioRetryBaseDelay = Duration(milliseconds: 400);
  static const Duration registrationLookupTtl = Duration(days: 1);

  // ── UI transitions ────────────────────────────────────────────────────────
  static const Duration captureStepDotTransition = Duration(milliseconds: 200);
  static const Duration helpCenterFaqChevron = Duration(milliseconds: 200);
  static const Duration earningsWeeklyBarChart = Duration(milliseconds: 450);
  static const Duration supportChatScrollToEnd = Duration(milliseconds: 280);
  static const Duration registrationStepScroll = Duration(milliseconds: 320);
}
