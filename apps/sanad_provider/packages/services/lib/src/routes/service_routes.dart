/// Route path constants for the services feature.
abstract final class ServiceRoutes {
  ServiceRoutes._();

  /// Provider services dashboard (shell deep-link: `/services`).
  static const String list = '/services';

  /// Add Service form, nested under [list].
  static const String add = '/services/add';

  /// Request New Service form, nested under [list].
  static const String requestNew = '/services/request-new';

  /// Per-service detail screen, nested under [list]. The page fetches the
  /// full service itself via `GET /provider-services/:id` — no `extra` is
  /// passed or required.
  static const String details = '/services/:id';

  static String detailsFor(String id) => '/services/$id';

  /// Per-request detail screen, nested under [list]. Reached with the full
  /// `ServiceRequestEntity` via the route `extra`.
  static const String requestDetails = '/services/requests/:id';

  static String requestDetailsFor(String id) => '/services/requests/$id';

  /// Edit Service form, nested under [list]. The page fetches the full
  /// service itself via `GET /provider-services/:id` — no `extra` is
  /// passed or required (same contract as [details]).
  static const String edit = '/services/:id/edit';

  static String editFor(String id) => '/services/$id/edit';

  static Set<String> get protectedRoutes => {list, add, requestNew};

  static bool isProtectedRoute(String location) =>
      protectedRoutes.contains(location);

  /// Whether [location] is one of the Services sub-surfaces the backend
  /// gates by owner persona rather than by a catalog permission (RBAC Phase
  /// 7E) — adding a service, requesting a new catalog service, viewing a
  /// service request, and editing a service. No permission exists for any
  /// provider-service or service-request write (RBAC Phase 7 finding G3), so
  /// a persona check is the only correct client gate. [list] and [details]
  /// are deliberately excluded — those stay permission-gated on
  /// `ServicePermissions.providerServiceView`, the same as viewing any other
  /// read-only surface.
  static bool isOwnerOnlyRoute(String location) =>
      location == add ||
      location == requestNew ||
      location.startsWith('$list/requests/') ||
      (location.startsWith('$list/') && location.endsWith('/edit'));
}
