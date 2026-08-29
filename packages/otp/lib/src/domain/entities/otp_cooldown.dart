import 'package:equatable/equatable.dart';

/// Server-owned resend state for a live OTP session.
///
/// Mirrors the shape every OTP family on the backend returns from its
/// `resend-info` endpoint (`contact-verification`, `auth`, `account/deletion`,
/// `workers/invitations`), so one engine can drive all of them:
///
/// ```json
/// { "canResend": true, "remainingSeconds": 0, "attemptsLeft": 4 }
/// ```
class OtpCooldown extends Equatable {
  const OtpCooldown({
    required this.canResend,
    required this.remainingSeconds,
    this.resendsLeft = unknownResendsLeft,
  });

  /// Sentinel for "the backend did not tell us" — never rendered.
  static const int unknownResendsLeft = -1;

  /// No live cooldown as far as we know. Used as the fail-open default when a
  /// flow exposes no `resend-info` endpoint, or the probe itself failed:
  /// stranding the user behind a cooldown the server never confirmed is worse
  /// than letting them try.
  static const OtpCooldown unknown = OtpCooldown(
    canResend: true,
    remainingSeconds: 0,
  );

  /// False while a session is cooling down, or when none is live.
  final bool canResend;

  /// Seconds to wait before the next resend is permitted.
  final int remainingSeconds;

  /// **Resends** still allowed for this session — the backend's `attemptsLeft`.
  ///
  /// This is deliberately *not* a wrong-code counter: no OTP endpoint in the
  /// contract exposes remaining verification attempts. Do not present it as
  /// one.
  final int resendsLeft;

  bool get hasKnownResendsLeft => resendsLeft >= 0;

  OtpCooldown copyWith({
    bool? canResend,
    int? remainingSeconds,
    int? resendsLeft,
  }) => OtpCooldown(
    canResend: canResend ?? this.canResend,
    remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    resendsLeft: resendsLeft ?? this.resendsLeft,
  );

  @override
  List<Object?> get props => [canResend, remainingSeconds, resendsLeft];
}
