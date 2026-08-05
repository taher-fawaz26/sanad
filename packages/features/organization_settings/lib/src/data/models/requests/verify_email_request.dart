import 'package:equatable/equatable.dart';

/// Body for `POST organizations/me/email/verify`.
class VerifyEmailRequest extends Equatable {
  const VerifyEmailRequest({required this.email, required this.otp});

  final String email;
  final String otp;

  Map<String, dynamic> toMap() => {'email': email, 'otp': otp};

  @override
  List<Object?> get props => [email, otp];
}
