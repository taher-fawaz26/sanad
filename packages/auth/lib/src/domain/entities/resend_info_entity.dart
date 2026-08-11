import 'package:equatable/equatable.dart';

/// Parsed `ResendInfoResponseDto` (`GET /auth/resend-info`) — the
/// server-driven OTP resend cooldown, replacing the client's old hardcoded
/// 60-second timer.
class ResendInfo extends Equatable {
  const ResendInfo({
    required this.canResend,
    required this.remainingSeconds,
    required this.attemptsLeft,
  });

  final bool canResend;
  final int remainingSeconds;
  final int attemptsLeft;

  @override
  List<Object?> get props => [canResend, remainingSeconds, attemptsLeft];
}
