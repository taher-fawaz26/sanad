/// API path constants for the real services/categories/service-requests
/// surface implemented in this task (P1 backend integration).
///
/// Deliberately distinct from the pre-existing [ServiceApiPaths] (singular,
/// in `service_api_paths.dart`), whose `services` constant
/// (`'provider/services'`) targets an unrelated branch-service-assignment
/// catalog endpoint consumed by the `branches` package. Do not rename or
/// merge these two — they hit different backend resources.
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
