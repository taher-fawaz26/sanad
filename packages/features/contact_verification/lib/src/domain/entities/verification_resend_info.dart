import 'package:equatable/equatable.dart';

/// Result of `GET /contact-verification/resend-info`.
class VerificationResendInfo extends Equatable {
  const VerificationResendInfo({
    required this.canResend,
    required this.remainingSeconds,
    required this.attemptsLeft,
  });

  /// `false` when no session is live, or the resend cooldown hasn't elapsed.
  final bool canResend;

  /// Seconds remaining before the next resend is allowed.
  final int remainingSeconds;

  /// Resends still allowed for this verification session.
  final int attemptsLeft;

  @override
  List<Object?> get props => [canResend, remainingSeconds, attemptsLeft];
}
