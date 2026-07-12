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

class DeleteAccountParams extends Equatable {
  const DeleteAccountParams({required this.userSub});

  final String userSub;

  @override
  List<Object?> get props => [userSub];
}
