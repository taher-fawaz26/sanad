import 'package:auth/src/domain/enums/user_type.dart';
import 'package:equatable/equatable.dart';

class LoginParams extends Equatable {
  const LoginParams({required this.identifier, required this.password});

  final String identifier;
  final String password;

  @override
  List<Object?> get props => [identifier, password];
}

class RegisterParams extends Equatable {
  const RegisterParams({
    required this.identifier,
    required this.password,
    required this.type,
  });

  final String identifier;
  final String password;
  final UserType type;

  @override
  List<Object?> get props => [identifier, password, type];
}

class ValidateOtpParams extends Equatable {
  const ValidateOtpParams({required this.identifier, required this.otp});

  final String identifier;
  final int otp;

  @override
  List<Object?> get props => [identifier, otp];
}

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

class ResendOtpParams extends Equatable {
  const ResendOtpParams({required this.identifier, required this.purpose});

  final String identifier;
  final String purpose;

  @override
  List<Object?> get props => [identifier, purpose];
}

class DeleteAccountParams extends Equatable {
  const DeleteAccountParams({required this.userSub});

  final String userSub;

  @override
  List<Object?> get props => [userSub];
}
