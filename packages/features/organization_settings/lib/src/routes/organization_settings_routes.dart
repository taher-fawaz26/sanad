/// Route paths owned by the organization_settings feature.
abstract final class OrganizationSettingsRoutes {
  OrganizationSettingsRoutes._();

  /// Organization KPI hub — hosted by the provider shell Settings tab.
  static const String hub = '/settings';

  /// Empty general settings placeholder — pushed from the KPI list.
  static const String general = '/settings/general';

  /// Routes that require an authenticated session.
  static const Set<String> protectedRoutes = {hub, general};
}
