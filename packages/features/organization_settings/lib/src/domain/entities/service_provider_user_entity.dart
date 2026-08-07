import 'package:auth/auth.dart';
import 'package:equatable/equatable.dart';

/// The authenticated user account behind the organization profile —
/// `ServiceProviderUserResponseDto`.
class ServiceProviderUserEntity extends Equatable {
  const ServiceProviderUserEntity({
    required this.id,
    required this.email,
    required this.userType,
    required this.isVerified,
    required this.isActive,
  });

  final String id;
  final String email;
  final UserType userType;
  final bool isVerified;
  final bool isActive;

  @override
  List<Object?> get props => [id, email, userType, isVerified, isActive];
}
