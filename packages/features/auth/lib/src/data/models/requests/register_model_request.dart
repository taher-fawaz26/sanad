import 'package:auth/src/domain/enums/user_type.dart';
import 'package:equatable/equatable.dart';

class RegisterModelRequest extends Equatable {
  const RegisterModelRequest({
    required this.identifier,
    required this.password,
    required this.type,
  });

  final String identifier;
  final String password;
  final UserType type;

  Map<String, dynamic> toMap() => {
        'identifier': identifier,
        'password': password,
        'type': type.value,
      };

  @override
  List<Object?> get props => [identifier, password, type];
}
