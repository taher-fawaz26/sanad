/// Route path constants for the services feature.
abstract final class ServiceRoutes {
  ServiceRoutes._();

  /// Provider services dashboard (shell deep-link: `/services`).
  static const String list = '/services';

  /// Add Service form, nested under [list].
  static const String add = '/services/add';

  /// Request New Service form, nested under [list].
  static const String requestNew = '/services/request-new';
}
