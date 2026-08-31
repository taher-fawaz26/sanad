class LocationPickerLabels {
  const LocationPickerLabels({
    required this.searchHint,
    required this.confirm,
    required this.specifiedLocation,
    required this.addressHint,
    required this.permissionDenied,
    required this.permissionPermanentlyDenied,
    required this.serviceDisabled,
    required this.genericError,
    required this.openSettings,
    required this.searchEmpty,
    required this.searchRetry,
    required this.outsideCountry,
    this.title,
    this.subtitle,
    this.placeIdRequiredHint,
  });

  /// Optional sheet header title (e.g. "Branch location").
  final String? title;

  /// Optional sheet header subtitle (e.g. "Move the pin to locate…").
  final String? subtitle;

  final String searchHint;
  final String confirm;
  final String specifiedLocation;
  final String addressHint;
  final String permissionDenied;
  final String permissionPermanentlyDenied;
  final String serviceDisabled;
  final String genericError;
  final String openSettings;

  /// Shown in the search sheet when a query returns no results.
  final String searchEmpty;

  /// Retry action shown in the search sheet on a search error.
  final String searchRetry;

  /// Shown when the picked location is outside the supported country (UAE).
  final String outsideCountry;

  /// Shown below the address field when `MapLocationPicker.requirePlaceId` is
  /// true but the current selection has no Google Place ID (e.g. the pin was
  /// dragged or the location came from GPS/plain geocoding). Prompts the user
  /// to pick a location from the search-autocomplete results instead.
  final String? placeIdRequiredHint;
}
