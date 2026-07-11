import 'package:equatable/equatable.dart';

class ForgotPasswordRequestParams extends Equatable {
  const ForgotPasswordRequestParams({required this.identifier});

  final String identifier;

  @override
  List<Object?> get props => [identifier];
}

class VerifyForgotPasswordOtpParams extends Equatable {
  const VerifyForgotPasswordOtpParams({
    required this.identifier,
    required this.otp,
  });

  final String identifier;
  final int otp;

  @override
  List<Object?> get props => [identifier, otp];
}

class ResetPasswordParams extends Equatable {
  const ResetPasswordParams({
    required this.identifier,
    required this.password,
  });

  final String identifier;
  final String password;

  @override
  List<Object?> get props => [identifier, password];
}
