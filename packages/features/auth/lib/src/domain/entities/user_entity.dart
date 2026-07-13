import 'package:auth/src/domain/enums/user_type.dart';
import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  const UserEntity({
    required this.sub,
    required this.identifier,
    required this.identifierType,
    required this.isVerified,
    required this.isProfileCompleted,
    required this.type,
  });

  final String sub;
  final String identifier;
  final String identifierType;
  final bool isVerified;
  final bool isProfileCompleted;

  /// Whether this account is a service provider or a client.
  final UserType type;

  @override
  List<Object?> get props => [
        sub,
        identifier,
        identifierType,
        isVerified,
        isProfileCompleted,
        type,
      ];
}
