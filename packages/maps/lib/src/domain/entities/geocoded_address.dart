import 'package:equatable/equatable.dart';

/// Structured result of a reverse-geocode lookup.
///
/// Carries both the full [formattedAddress] (useful for showing the exact
/// picked location) and a human-friendly [areaName] (neighborhood / locality)
/// suitable for display as an area label. Keeping both here means consuming
/// features never parse raw geocoder responses themselves.
class GeocodedAddress extends Equatable {
  const GeocodedAddress({
    required this.formattedAddress,
    this.areaName,
    this.isoCountryCode,
    this.placeId,
  });

  /// The full, comma-joined address (street, locality, country, ...).
  final String formattedAddress;

  /// The best human-friendly area name (neighborhood → sublocality → locality
  /// → administrative area → place name). Null when none could be derived.
  final String? areaName;

  /// ISO 3166-1 alpha-2 country code of the resolved location (e.g. `AE`),
  /// uppercased. Null when the geocoder did not provide one. Used to keep
  /// selection inside the supported country.
  final String? isoCountryCode;

  /// The Google `place_id` for the resolved location, when the reverse-geocode
  /// came from a Google source (the REST Geocoding API). Null for the platform
  /// geocoder, which does not expose a Place ID. This is what lets a
  /// map-dragged / current-location point carry a real, submittable Place ID
  /// — the same canonical id the backend requires — without forcing the user
  /// to pick a search result (SAN-778 follow-up).
  final String? placeId;

  @override
  List<Object?> get props => [
    formattedAddress,
    areaName,
    isoCountryCode,
    placeId,
  ];
}
