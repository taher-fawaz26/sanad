part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => const [];
}

class AuthInitialState extends AuthState {
  const AuthInitialState();
}

class AuthRegisterLoadingState extends AuthState {
  const AuthRegisterLoadingState();
}

class AuthRegisterSuccessState extends AuthState {
  const AuthRegisterSuccessState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class AuthRegisterFailureState extends AuthState {
  const AuthRegisterFailureState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class AuthLoginLoadingState extends AuthState {
  const AuthLoginLoadingState();
}

class AuthLoginSuccessState extends AuthState {
  const AuthLoginSuccessState(this.user);

  final UserEntity user;

  @override
  List<Object?> get props => [user];
}

class AuthLoginFailureState extends AuthState {
  const AuthLoginFailureState(this.message, {this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

/// Login failed because the account is not verified — navigate to OTP.
class AuthLoginUnverifiedState extends AuthState {
  const AuthLoginUnverifiedState();
}

class AuthLogoutLoadingState extends AuthState {
  const AuthLogoutLoadingState();
}

class AuthLogoutSuccessState extends AuthState {
  const AuthLogoutSuccessState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class AuthLogoutFailureState extends AuthState {
  const AuthLogoutFailureState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class AuthDeleteAccountLoadingState extends AuthState {
  const AuthDeleteAccountLoadingState(this.user);

  final UserEntity user;

  @override
  List<Object?> get props => [user];
}

class AuthDeleteAccountFailureState extends AuthState {
  const AuthDeleteAccountFailureState(this.message, {required this.user});

  final String message;
  final UserEntity? user;

  @override
  List<Object?> get props => [message, user];
}

class AuthCheckSignInStatusLoadingState extends AuthState {
  const AuthCheckSignInStatusLoadingState();
}

class AuthCheckSignInStatusSuccessState extends AuthState {
  const AuthCheckSignInStatusSuccessState(this.user);

  final UserEntity user;

  @override
  List<Object?> get props => [user];
}

class AuthCheckSignInStatusFailureState extends AuthState {
  const AuthCheckSignInStatusFailureState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
