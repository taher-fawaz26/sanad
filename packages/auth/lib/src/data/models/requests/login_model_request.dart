import 'package:equatable/equatable.dart';

class LoginModelRequest extends Equatable {
  const LoginModelRequest({required this.identifier, required this.password});

  final String identifier;
  final String password;

  Map<String, dynamic> toMap() => {
        'identifier': identifier,
        'password': password,
      };

  @override
  List<Object?> get props => [identifier, password];
}
