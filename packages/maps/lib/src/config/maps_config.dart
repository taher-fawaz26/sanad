enum PlacesProviderType {
  google,
  backend,
  openStreetMap,
}

class MapsConfig {
  const MapsConfig({
    this.placesApiKey,
    this.placesProvider = PlacesProviderType.google,
    this.countryCode = 'ae',
  });

  final String? placesApiKey;
  final PlacesProviderType placesProvider;

  /// ISO 3166-1 alpha-2 country code that place search and area lookups are
  /// restricted to. Defaults to the UAE (`ae`) — providers manage UAE
  /// businesses, so no place outside the country may be selected.
  final String countryCode;

  bool get placesEnabled => placesApiKey != null && placesApiKey!.isNotEmpty;
}
