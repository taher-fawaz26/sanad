part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Request an OTP for [email] (shared by Sign In and Sign Up).
class AuthRequestOtpEvent extends AuthEvent {
  const AuthRequestOtpEvent(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

/// Verify the [otp] entered for [email].
class AuthVerifyOtpEvent extends AuthEvent {
  const AuthVerifyOtpEvent({required this.email, required this.otp});

  final String email;
  final String otp;

  @override
  List<Object?> get props => [email, otp];
}

class AuthLogoutEvent extends AuthEvent {}

class AuthDeleteAccountEvent extends AuthEvent {
  const AuthDeleteAccountEvent(this.userSub);

  final String userSub;

  @override
  List<Object?> get props => [userSub];
}

class AuthCheckSignInStatusEvent extends AuthEvent {}
