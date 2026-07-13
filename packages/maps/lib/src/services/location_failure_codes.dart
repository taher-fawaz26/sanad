/// Stable [Failure.code] values for location-related errors.
abstract final class LocationFailureCodes {
  LocationFailureCodes._();

  static const String permissionDenied = 'location_permission_denied';
  static const String permissionPermanentlyDenied =
      'location_permission_permanently_denied';
  static const String serviceDisabled = 'location_service_disabled';
  static const String unavailable = 'location_unavailable';
  static const String geocodingFailed = 'geocoding_failed';
}
