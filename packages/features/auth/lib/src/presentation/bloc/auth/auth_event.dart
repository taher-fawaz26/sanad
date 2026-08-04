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

class AuthLogoutEvent extends AuthEvent {}

class AuthDeleteAccountEvent extends AuthEvent {
  const AuthDeleteAccountEvent(this.userSub);

  final String userSub;

  @override
  List<Object?> get props => [userSub];
}

class AuthCheckSignInStatusEvent extends AuthEvent {}

class AuthGoogleSignInEvent extends AuthEvent {}

class AuthValidateEmailEvent extends AuthEvent {
  const AuthValidateEmailEvent({required this.email, required this.isLogin});

  final String email;
  final bool isLogin;

  @override
  List<Object?> get props => [email];
}
