/// Route path constants for the services feature.
abstract final class ServiceRoutes {
  ServiceRoutes._();

  /// Provider services dashboard (shell deep-link: `/services`).
  static const String list = '/services';

  /// Add Service form, nested under [list].
  static const String add = '/services/add';

  /// Request New Service form, nested under [list].
  static const String requestNew = '/services/request-new';

  /// Per-service detail screen, nested under [list]. Reached with the full
  /// `ProviderServiceEntity` via the route `extra` (the list already holds
  /// it) — the `:id` segment is for deep-linkability only, not used to
  /// re-fetch.
  static const String details = '/services/:id';

  static String detailsFor(String id) => '/services/$id';

  /// Per-request detail screen, nested under [list]. Reached with the full
  /// `ServiceRequestEntity` via the route `extra`.
  static const String requestDetails = '/services/requests/:id';

  static String requestDetailsFor(String id) => '/services/requests/$id';

  /// Edit Service form, nested under [list]. Reached with the full
  /// `ProviderServiceEntity` via the route `extra`.
  static const String edit = '/services/:id/edit';

  static String editFor(String id) => '/services/$id/edit';

  static Set<String> get protectedRoutes => {list, add, requestNew};

  static bool isProtectedRoute(String location) =>
      protectedRoutes.contains(location);
}
