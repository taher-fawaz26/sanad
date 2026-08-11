import 'package:equatable/equatable.dart';

/// Result of `POST /contact-verification/{request,resend}`.
class VerificationDispatch extends Equatable {
  const VerificationDispatch({required this.message, this.devCode});

  final String message;

  /// The OTP itself — only ever returned in development (`DEFAULT_OTP`
  /// short-circuit). `null` in production.
  final String? devCode;

  @override
  List<Object?> get props => [message, devCode];
}
