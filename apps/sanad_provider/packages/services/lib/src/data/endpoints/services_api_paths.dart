/// API path constants for the real categories / catalog / provider-services
/// / service-requests surface, confirmed against the live OpenAPI spec
/// (`https://dev-api.trysanad.us/api/docs-json`).
abstract final class ServicesApiPaths {
  ServicesApiPaths._();

  static const String categories = 'categories';

  static const String serviceRequests = 'service-requests';

  static String serviceRequest(String id) => 'service-requests/$id';

  /// Catalog discovery only — `GET services?...` is the browsable master
  /// catalog a provider picks a `serviceId` from. Not "my services".
  static const String catalogServices = 'services';

  static const String providerServices = 'provider-services';

  static String providerService(String id) => 'provider-services/$id';

  static String providerServiceStatus(String id) =>
      'provider-services/$id/status';

  static const String providerServicesOverview = 'provider-services/overview';

  static String providerServiceImages(String id) =>
      'provider-services/$id/images';

  static String providerServiceImage(String id, String imageId) =>
      'provider-services/$id/images/$imageId';

  static String providerServiceImagePrimary(String id, String imageId) =>
      'provider-services/$id/images/$imageId/primary';
}
