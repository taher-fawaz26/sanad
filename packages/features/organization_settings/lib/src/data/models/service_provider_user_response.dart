import 'package:auth/auth.dart';
import 'package:organization_settings/src/domain/entities/service_provider_user_entity.dart';

/// Mirrors `ServiceProviderUserResponseDto` exactly.
class ServiceProviderUserResponse {
  const ServiceProviderUserResponse({
    required this.id,
    required this.email,
    required this.userType,
    required this.isVerified,
    required this.isActive,
  });

  factory ServiceProviderUserResponse.fromJson(Map<String, dynamic> json) {
    return ServiceProviderUserResponse(
      id: json['id'] as String,
      email: json['email'] as String,
      userType: UserType.fromJson(json['userType'] as String),
      isVerified: json['isVerified'] as bool,
      isActive: json['isActive'] as bool,
    );
  }

  final String id;
  final String email;
  final UserType userType;
  final bool isVerified;
  final bool isActive;

  ServiceProviderUserEntity toEntity() => ServiceProviderUserEntity(
    id: id,
    email: email,
    userType: userType,
    isVerified: isVerified,
    isActive: isActive,
  );
}
