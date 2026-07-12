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
