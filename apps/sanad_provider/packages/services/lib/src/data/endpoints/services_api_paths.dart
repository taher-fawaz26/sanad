/// API path constants for the real services/categories/service-requests
/// surface, confirmed against the live OpenAPI spec
/// (`https://dev-api.trysanad.us/api/docs-json`).
///
/// There used to be a second, singular `ServiceApiPaths`/`ServiceRepository`
/// pointed at `'provider/services'` for the branch-service-assignment
/// picker — that path does not exist on the live backend at all. It has
/// been removed; the picker (`select_service_action_sheet.dart`) now loads
/// from this same `services` contract via `GetServicesListUseCase`.
abstract final class ServicesApiPaths {
  ServicesApiPaths._();

  static const String categories = 'categories';

  static const String services = 'services';

  static String service(String id) => 'services/$id';

  static String serviceStatus(String id) => 'services/$id/status';

  static const String serviceAnalytics = 'services/analytics';

  static const String serviceRequests = 'service-requests';

  static const String myServiceRequests = 'service-requests/mine';
}
