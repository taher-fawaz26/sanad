import 'package:equatable/equatable.dart';

/// `EmailOtpDto` — body shared by `POST /auth/signup/verify` and
/// `POST /auth/login/verify`.
class VerifyEmailOtpRequest extends Equatable {
  const VerifyEmailOtpRequest({required this.email, required this.otp});

  final String email;
  final String otp;

  Map<String, dynamic> toMap() => {'email': email, 'otp': otp};

  @override
  List<Object?> get props => [email, otp];
}
