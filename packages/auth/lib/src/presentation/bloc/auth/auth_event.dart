part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoginEvent extends AuthEvent {
  const AuthLoginEvent(this.identifier, this.password);

  final String identifier;
  final String password;

  @override
  List<Object?> get props => [identifier, password];
}

class AuthRegisterEvent extends AuthEvent {
  const AuthRegisterEvent(this.identifier, this.password, this.type);

  final String identifier;
  final String password;
  final UserType type;

  @override
  List<Object?> get props => [identifier, password, type];
}

class AuthLogoutEvent extends AuthEvent {}

class AuthDeleteAccountEvent extends AuthEvent {
  const AuthDeleteAccountEvent(this.userSub);

  final String userSub;

  @override
  List<Object?> get props => [userSub];
}

class AuthCheckSignInStatusEvent extends AuthEvent {}

class AuthValidateOtpEvent extends AuthEvent {
  const AuthValidateOtpEvent(this.identifier, this.otp);

  final String identifier;
  final int otp;

  @override
  List<Object?> get props => [identifier, otp];
}

class AuthForgotPasswordRequestEvent extends AuthEvent {
  const AuthForgotPasswordRequestEvent(this.identifier);

  final String identifier;

  @override
  List<Object?> get props => [identifier];
}

class AuthVerifyForgotPasswordOtpEvent extends AuthEvent {
  const AuthVerifyForgotPasswordOtpEvent(this.identifier, this.otp);

  final String identifier;
  final int otp;

  @override
  List<Object?> get props => [identifier, otp];
}

class AuthResendForgotPasswordOtpEvent extends AuthEvent {
  const AuthResendForgotPasswordOtpEvent(this.identifier);

  final String identifier;

  @override
  List<Object?> get props => [identifier];
}

class AuthResetPasswordEvent extends AuthEvent {
  const AuthResetPasswordEvent(this.identifier, this.password);

  final String identifier;
  final String password;

  @override
  List<Object?> get props => [identifier, password];
}

class AuthResendOtpEvent extends AuthEvent {
  const AuthResendOtpEvent(this.identifier, this.purpose);

  final String identifier;
  final String purpose;

  @override
  List<Object?> get props => [identifier, purpose];
}
