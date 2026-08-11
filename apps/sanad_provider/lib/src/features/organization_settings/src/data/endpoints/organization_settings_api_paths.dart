/// Backend endpoints for the organization settings root profile.
abstract final class OrganizationSettingsApiPaths {
  OrganizationSettingsApiPaths._();

  /// `GET` — `MeSettingsResponseDto { businessProfile }`. The lean
  /// `service-provider/profile` identity endpoint does NOT carry business
  /// fields (businessName, categories, trade licence, social profiles, …) —
  /// this is the only endpoint that does.
  static const String settings = 'settings';
}
