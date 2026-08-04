/// Backend endpoints for organization identity media.
///
/// TODO(endpoint): confirm these paths with the backend once the organization
/// media upload/remove endpoints are finalized in the API spec.
abstract final class OrganizationMediaApiPaths {
  OrganizationMediaApiPaths._();

  static const String cover = 'organizations/me/cover';
  static const String logo = 'organizations/me/logo';
}
