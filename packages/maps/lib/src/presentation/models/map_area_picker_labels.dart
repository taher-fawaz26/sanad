class MapAreaPickerLabels {
  const MapAreaPickerLabels({
    required this.title,
    required this.searchHint,
    required this.noResultsMessage,
    required this.searchError,
    required this.specifiedLocation,
    required this.addressHint,
    required this.genericError,
    required this.confirm,
    required this.searchRetry,
    this.placeIdRequiredHint,
  });

  final String title;
  final String searchHint;
  final String noResultsMessage;
  final String searchError;
  final String specifiedLocation;
  final String addressHint;
  final String genericError;
  final String confirm;

  /// Retry action shown in the search sheet on a search error.
  final String searchRetry;

  /// Shown below the address field when [MapAreaPicker.requirePlaceId] is true
  /// and the current location was not selected from search results.
  final String? placeIdRequiredHint;
}
