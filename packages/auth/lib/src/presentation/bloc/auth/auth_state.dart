part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState({this.status = AuthStatus.unknown});

  final AuthStatus status;

  @override
  List<Object?> get props => [status];
}

class AuthInitialState extends AuthState {
  const AuthInitialState() : super(status: AuthStatus.unknown);
}

// ── Register ─────────────────────────────────────────────────────────────────

class AuthRegisterLoadingState extends AuthState {
  const AuthRegisterLoadingState() : super(status: AuthStatus.unknown);
}

class AuthRegisterSuccessState extends AuthState {
  const AuthRegisterSuccessState(this.message)
      : super(status: AuthStatus.unknown);

  final String message;

  @override
  List<Object?> get props => [status, message];
}

class AuthRegisterFailureState extends AuthState {
  const AuthRegisterFailureState(this.message)
      : super(status: AuthStatus.unknown);

  final String message;

  @override
  List<Object?> get props => [status, message];
}

// ── Login ────────────────────────────────────────────────────────────────────

class AuthLoginLoadingState extends AuthState {
  const AuthLoginLoadingState() : super(status: AuthStatus.unknown);
}

class AuthLoginSuccessState extends AuthState {
  const AuthLoginSuccessState(this.user)
      : super(status: AuthStatus.authenticated);

  final UserEntity user;

  @override
  List<Object?> get props => [status, user];
}

class AuthLoginFailureState extends AuthState {
  const AuthLoginFailureState(this.message, {this.code})
      : super(status: AuthStatus.unknown);

  final String message;
  final String? code;

  @override
  List<Object?> get props => [status, message, code];
}

/// Login failed because the account is not verified — navigate to OTP.
class AuthLoginUnverifiedState extends AuthState {
  const AuthLoginUnverifiedState() : super(status: AuthStatus.unknown);
}

// ── Logout ───────────────────────────────────────────────────────────────────

class AuthLogoutLoadingState extends AuthState {
  const AuthLogoutLoadingState() : super(status: AuthStatus.unauthenticated);
}

class AuthLogoutSuccessState extends AuthState {
  const AuthLogoutSuccessState(this.message)
      : super(status: AuthStatus.unauthenticated);

  final String message;

  @override
  List<Object?> get props => [status, message];
}

class AuthLogoutFailureState extends AuthState {
  const AuthLogoutFailureState(this.message)
      : super(status: AuthStatus.unauthenticated);

  final String message;

  @override
  List<Object?> get props => [status, message];
}

// ── Delete Account ───────────────────────────────────────────────────────────

class AuthDeleteAccountLoadingState extends AuthState {
  const AuthDeleteAccountLoadingState(this.user)
      : super(status: AuthStatus.authenticated);

  final UserEntity user;

  @override
  List<Object?> get props => [status, user];
}

class AuthDeleteAccountFailureState extends AuthState {
  const AuthDeleteAccountFailureState(this.message, {required this.user})
      : super(status: AuthStatus.authenticated);

  final String message;
  final UserEntity? user;

  @override
  List<Object?> get props => [status, message, user];
}

// ── Check Sign-In Status ─────────────────────────────────────────────────────

class AuthCheckSignInStatusLoadingState extends AuthState {
  const AuthCheckSignInStatusLoadingState() : super(status: AuthStatus.unknown);
}

class AuthCheckSignInStatusSuccessState extends AuthState {
  const AuthCheckSignInStatusSuccessState(this.user)
      : super(status: AuthStatus.authenticated);

  final UserEntity user;

  @override
  List<Object?> get props => [status, user];
}

class AuthCheckSignInStatusFailureState extends AuthState {
  const AuthCheckSignInStatusFailureState(this.message)
      : super(status: AuthStatus.unauthenticated);

  final String message;

  @override
  List<Object?> get props => [status, message];
}

// ── Validate OTP ─────────────────────────────────────────────────────────────

class AuthValidateOtpLoadingState extends AuthState {
  const AuthValidateOtpLoadingState() : super(status: AuthStatus.unknown);
}

class AuthValidateOtpSuccessState extends AuthState {
  const AuthValidateOtpSuccessState(this.user, this.message)
      : super(status: AuthStatus.authenticated);

  final UserEntity user;
  final String message;

  @override
  List<Object?> get props => [status, user, message];
}

class AuthValidateOtpFailureState extends AuthState {
  const AuthValidateOtpFailureState(this.message)
      : super(status: AuthStatus.unauthenticated);

  final String message;

  @override
  List<Object?> get props => [status, message];
}

// ── Forgot Password ──────────────────────────────────────────────────────────

class AuthForgotPasswordRequestLoadingState extends AuthState {
  const AuthForgotPasswordRequestLoadingState()
      : super(status: AuthStatus.unauthenticated);
}

class AuthForgotPasswordOtpSentState extends AuthState {
  const AuthForgotPasswordOtpSentState()
      : super(status: AuthStatus.unauthenticated);
}

class AuthForgotPasswordRequestFailureState extends AuthState {
  const AuthForgotPasswordRequestFailureState(this.message)
      : super(status: AuthStatus.unauthenticated);

  final String message;

  @override
  List<Object?> get props => [status, message];
}

class AuthForgotPasswordOtpVerifyLoadingState extends AuthState {
  const AuthForgotPasswordOtpVerifyLoadingState()
      : super(status: AuthStatus.unauthenticated);
}

class AuthForgotPasswordOtpResendLoadingState extends AuthState {
  const AuthForgotPasswordOtpResendLoadingState()
      : super(status: AuthStatus.unauthenticated);
}

class AuthForgotPasswordOtpReadyState extends AuthState {
  const AuthForgotPasswordOtpReadyState()
      : super(status: AuthStatus.unauthenticated);
}

class AuthForgotPasswordOtpVerifiedState extends AuthState {
  const AuthForgotPasswordOtpVerifiedState()
      : super(status: AuthStatus.unauthenticated);
}

class AuthForgotPasswordOtpFailureState extends AuthState {
  const AuthForgotPasswordOtpFailureState(this.message)
      : super(status: AuthStatus.unauthenticated);

  final String message;

  @override
  List<Object?> get props => [status, message];
}

// ── Reset Password ───────────────────────────────────────────────────────────

class AuthResetPasswordLoadingState extends AuthState {
  const AuthResetPasswordLoadingState()
      : super(status: AuthStatus.unauthenticated);
}

class AuthResetPasswordSuccessState extends AuthState {
  const AuthResetPasswordSuccessState()
      : super(status: AuthStatus.unauthenticated);
}

class AuthResetPasswordFailureState extends AuthState {
  const AuthResetPasswordFailureState(this.message)
      : super(status: AuthStatus.unauthenticated);

  final String message;

  @override
  List<Object?> get props => [status, message];
}

// ── Resend OTP ───────────────────────────────────────────────────────────────

class AuthResendOtpLoadingState extends AuthState {
  const AuthResendOtpLoadingState() : super(status: AuthStatus.unknown);
}

class AuthResendOtpSuccessState extends AuthState {
  const AuthResendOtpSuccessState() : super(status: AuthStatus.unknown);
}

class AuthResendOtpFailureState extends AuthState {
  const AuthResendOtpFailureState(this.message)
      : super(status: AuthStatus.unknown);

  final String message;

  @override
  List<Object?> get props => [status, message];
}
