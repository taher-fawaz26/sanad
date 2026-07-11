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
