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

  /// The account email — `null` for phone-registered clients (a phone-only
  /// client has `phone` set and no email). Providers/workers always have one.
  final String? email;
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
