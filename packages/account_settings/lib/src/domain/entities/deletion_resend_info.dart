import 'package:equatable/equatable.dart';

/// `AccountDeletionResendInfoDto` (`GET /account/deletion/resend-info`) —
/// server-driven OTP resend cooldown. No client timer is invented; the UI
/// only ever reflects these three fields.
class DeletionResendInfo extends Equatable {
  const DeletionResendInfo({
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
