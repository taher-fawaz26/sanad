import 'package:equatable/equatable.dart';

/// Params for `EmailDto` calls — shared by signup, login, and resend-otp
/// (all three are just `{email}` on the wire).
class RequestEmailOtpParams extends Equatable {
  const RequestEmailOtpParams({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

/// Params for `EmailOtpDto` calls — shared by signup/verify and login/verify.
class VerifyEmailOtpParams extends Equatable {
  const VerifyEmailOtpParams({required this.email, required this.otp});

  final String email;
  final String otp;

  @override
  List<Object?> get props => [email, otp];
}
