/// Stable failure code values for location-related errors.
abstract final class LocationFailureCodes {
  LocationFailureCodes._();

  static const String permissionDenied = 'location_permission_denied';
  static const String permissionPermanentlyDenied =
      'location_permission_permanently_denied';
  static const String serviceDisabled = 'location_service_disabled';
  static const String unavailable = 'location_unavailable';

  /// Fetching the device position exceeded the time limit — distinct from a
  /// hard [unavailable] so the UI can offer a plain retry.
  static const String timeout = 'location_timeout';
  static const String geocodingFailed = 'geocoding_failed';

  /// The resolved position falls outside the supported country (the UAE) —
  /// e.g. a provider physically abroad tapping "use my current location".
  static const String outsideSupportedCountry = 'location_outside_country';
}
