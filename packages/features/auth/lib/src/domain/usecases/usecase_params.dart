import 'package:equatable/equatable.dart';

/// Params for `POST /auth/email/request-otp`.
class RequestEmailOtpParams extends Equatable {
  const RequestEmailOtpParams({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

/// Params for `POST /auth/email/verify`.
class VerifyEmailOtpParams extends Equatable {
  const VerifyEmailOtpParams({required this.email, required this.otp});

  final String email;
  final String otp;

  @override
  List<Object?> get props => [email, otp];
}

class DeleteAccountParams extends Equatable {
  const DeleteAccountParams({required this.userSub});

  final String userSub;

  @override
  List<Object?> get props => [userSub];
}
