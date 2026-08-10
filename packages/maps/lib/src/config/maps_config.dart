enum PlacesProviderType {
  google,
  backend,
  openStreetMap,
}

/// Tunables for Google-only serving-area discovery (grid-tessellated
/// reverse geocoding). See `GoogleNearbyAreasRepositoryImpl`.
class ServingAreaDiscoveryConfig {
  const ServingAreaDiscoveryConfig({
    this.gridSpacingKm = 1.5,
    this.maxSamples = 40,
    this.maxRadiusKm = 15,
    this.concurrency = 8,
  });

  /// Spacing between grid sample points, in kilometers.
  final double gridSpacingKm;

  /// Hard cap on reverse-geocode calls per discovery. When the generated
  /// grid would exceed this, spacing is coarsened until it fits.
  final int maxSamples;

  /// Maximum radius (km) a user may select for a branch's coverage area.
  /// This is a product/config limit, not a Google API limit.
  final double maxRadiusKm;

  /// Maximum reverse-geocode requests in flight at once.
  final int concurrency;
}

class MapsConfig {
  const MapsConfig({
    this.placesApiKey,
    this.placesProvider = PlacesProviderType.google,
    this.countryCode = 'ae',
    this.servingAreaDiscovery = const ServingAreaDiscoveryConfig(),
  });

  final String? placesApiKey;
  final PlacesProviderType placesProvider;

  /// ISO 3166-1 alpha-2 country code that place search and area lookups are
  /// restricted to. Defaults to the UAE (`ae`) — providers manage UAE
  /// businesses, so no place outside the country may be selected.
  final String countryCode;

  final ServingAreaDiscoveryConfig servingAreaDiscovery;

  bool get placesEnabled => placesApiKey != null && placesApiKey!.isNotEmpty;
}
