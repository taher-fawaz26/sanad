/// Backend endpoint for updating the organization's business settings.
///
/// Distinct from `OrganizationSettingsApiPaths.settings` (`GET /settings`,
/// the "Me" read model) and from `account_settings`' `PATCH
/// /account-settings` (the provider owner's own name/language) — this is
/// `PATCH service-provider/settings`: business description, categories, and
/// social profiles.
abstract final class ServiceProviderSettingsApiPaths {
  ServiceProviderSettingsApiPaths._();

  /// `PATCH` — `UpdateServiceProviderSettingsDto` → `204 No Content`.
  static const String settings = 'service-provider/settings';
}
