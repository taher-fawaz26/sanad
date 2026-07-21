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
  const AuthRegisterFailureState(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
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
  const AuthLoginFailureState(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
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
  const AuthLogoutFailureState(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

class AuthDeleteAccountLoadingState extends AuthState {
  const AuthDeleteAccountLoadingState(this.user);

  final UserEntity user;

  @override
  List<Object?> get props => [user];
}

class AuthDeleteAccountFailureState extends AuthState {
  const AuthDeleteAccountFailureState(this.failure, {required this.user});

  final Failure failure;
  final UserEntity? user;

  @override
  List<Object?> get props => [failure, user];
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
