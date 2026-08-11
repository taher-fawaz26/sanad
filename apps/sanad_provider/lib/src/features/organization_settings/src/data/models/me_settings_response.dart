import 'package:sanad_provider/src/features/organization_settings/src/data/models/business_profile_me_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/organization_profile_entity.dart';

/// Mirrors `MeSettingsResponseDto` exactly — the response envelope for
/// `GET /settings`.
///
/// A provider owner gets their own business; a worker/manager gets their
/// employer's. A client or admin belongs to no business and gets a 404 —
/// not reachable from this provider-only feature, but the datasource still
/// surfaces it as a normal [Failure] rather than crashing.
class MeSettingsResponse {
  const MeSettingsResponse({required this.businessProfile});

  factory MeSettingsResponse.fromJson(Map<String, dynamic> json) {
    return MeSettingsResponse(
      businessProfile: BusinessProfileMeResponse.fromJson(
        json['businessProfile'] as Map<String, dynamic>,
      ),
    );
  }

  final BusinessProfileMeResponse businessProfile;

  OrganizationProfileEntity toEntity() => businessProfile.toEntity();
}
