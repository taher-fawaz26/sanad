import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/geocoded_address.dart';

/// Reverse-geocodes a coordinate to a [GeocodedAddress] that carries a real
/// Google `place_id`.
///
/// This exists so a map-dragged pin or a current-location fix can obtain the
/// **same** canonical Place ID the backend requires — from ONE Google result
/// (place id + formatted address + country) — without forcing the user to pick
/// a search-autocomplete result. Backed by the Google REST Geocoding API; only
/// wired when the Google places provider is configured.
abstract class ReverseGeocodePlaceRepository {
  /// Returns the best place for [position], or `null` when Google returns no
  /// result for the coordinate (e.g. open water). A failure is returned only
  /// for genuine errors (network / key / quota).
  TaskEither<Failure, GeocodedAddress?> reverseGeocodePlace({
    required LatLng position,
    String? languageCode,
  });
}
