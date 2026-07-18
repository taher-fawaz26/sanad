enum PlacesProviderType {
  google,
  backend,
  openStreetMap,
}

class MapsConfig {
  const MapsConfig({
    this.placesApiKey,
    this.placesProvider = PlacesProviderType.google,
  });

  final String? placesApiKey;
  final PlacesProviderType placesProvider;

  bool get placesEnabled => placesApiKey != null && placesApiKey!.isNotEmpty;
}
