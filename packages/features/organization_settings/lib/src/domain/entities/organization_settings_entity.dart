import 'package:equatable/equatable.dart';
import 'package:organization_settings/src/domain/entities/organization_profile_entity.dart';
import 'package:organization_settings/src/domain/entities/service_provider_user_entity.dart';

/// Single source of truth for the entire Organization Settings feature —
/// `GET /service-provider/me`.
///
/// Every section on the general settings page (Identity, Category, Contact
/// Information, Social Profiles, Compliance Documents, Working Hours,
/// header) reads from this one root entity instead of independent models or
/// mocked state.
class OrganizationSettingsEntity extends Equatable {
  const OrganizationSettingsEntity({
    required this.user,
    required this.profile,
  });

  final ServiceProviderUserEntity user;
  final OrganizationProfileEntity profile;

  @override
  List<Object?> get props => [user, profile];
}
