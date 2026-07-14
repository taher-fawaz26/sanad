import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Repository contract for geocoding operations.
///
/// Consumers depend on this contract. The concrete implementation handles
/// caching, locale management, and delegation to platform services.
abstract class GeocodingRepository {
  TaskEither<Failure, String> reverseGeocode(
    LatLng position, {
    String? localeIdentifier,
  });

  TaskEither<Failure, LatLng> forwardGeocode(
    String address, {
    String? localeIdentifier,
  });

  TaskEither<Failure, List<String>> nearbyAreaNames({
    required LatLng center,
    required double radiusKm,
    String? localeIdentifier,
  });
}
