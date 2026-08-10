import 'package:equatable/equatable.dart';

/// `EmailDto` — body shared by `POST /auth/signup`, `POST /auth/login`, and
/// `POST /auth/resend-otp`.
class EmailOtpRequest extends Equatable {
  const EmailOtpRequest({required this.email});

  final String email;

  Map<String, dynamic> toMap() => {'email': email};

  @override
  List<Object?> get props => [email];
}
