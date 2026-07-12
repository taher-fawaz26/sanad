part of 'forgot_password_bloc.dart';

sealed class ForgotPasswordEvent extends Equatable {
  const ForgotPasswordEvent();

  @override
  List<Object?> get props => [];
}

class ForgotPasswordRequestEvent extends ForgotPasswordEvent {
  const ForgotPasswordRequestEvent(this.identifier);

  final String identifier;

  @override
  List<Object?> get props => [identifier];
}

class ForgotPasswordVerifyOtpEvent extends ForgotPasswordEvent {
  const ForgotPasswordVerifyOtpEvent(this.identifier, this.otp);

  final String identifier;
  final int otp;

  @override
  List<Object?> get props => [identifier, otp];
}

class ForgotPasswordResendOtpEvent extends ForgotPasswordEvent {
  const ForgotPasswordResendOtpEvent(this.identifier);

  final String identifier;

  @override
  List<Object?> get props => [identifier];
}

class ForgotPasswordResetEvent extends ForgotPasswordEvent {
  const ForgotPasswordResetEvent(this.identifier, this.password);

  final String identifier;
  final String password;

  @override
  List<Object?> get props => [identifier, password];
}
