import 'package:organization_settings/src/data/models/business_profile_me_response.dart';
import 'package:organization_settings/src/data/models/service_provider_user_response.dart';
import 'package:organization_settings/src/domain/entities/organization_settings_entity.dart';

/// Mirrors `ServiceProviderMeResponseDto` exactly — the response envelope
/// for `GET /service-provider/me`.
class ServiceProviderMeResponse {
  const ServiceProviderMeResponse({required this.user, required this.profile});

  factory ServiceProviderMeResponse.fromJson(Map<String, dynamic> json) {
    return ServiceProviderMeResponse(
      user: ServiceProviderUserResponse.fromJson(
        json['user'] as Map<String, dynamic>,
      ),
      profile: BusinessProfileMeResponse.fromJson(
        json['profile'] as Map<String, dynamic>,
      ),
    );
  }

  final ServiceProviderUserResponse user;
  final BusinessProfileMeResponse profile;

  OrganizationSettingsEntity toEntity() => OrganizationSettingsEntity(
    user: user.toEntity(),
    profile: profile.toEntity(),
  );
}
