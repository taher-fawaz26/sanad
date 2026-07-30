import 'package:equatable/equatable.dart';

/// Body for `POST /auth/email/request-otp`.
class EmailOtpRequest extends Equatable {
  const EmailOtpRequest({required this.email});

  final String email;

  Map<String, dynamic> toMap() => {'email': email};

  @override
  List<Object?> get props => [email];
}
