import 'package:auth/src/domain/enums/user_type.dart';
import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    required this.isVerified,
    required this.isActive,
    required this.type,
  });

  final String id;
  final String email;
  final bool isVerified;
  final bool? isActive;

  /// Whether this account is a service provider or a client.
  final UserType? type;

  @override
  List<Object?> get props => [
    id,
    email,
    isVerified,
    isActive,
    type,
  ];
}
