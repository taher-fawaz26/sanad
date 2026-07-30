import 'package:equatable/equatable.dart';

/// Body for `POST /auth/email/verify`.
class VerifyEmailOtpRequest extends Equatable {
  const VerifyEmailOtpRequest({required this.email, required this.otp});

  final String email;
  final String otp;

  Map<String, dynamic> toMap() => {'email': email, 'otp': otp};

  @override
  List<Object?> get props => [email, otp];
}
