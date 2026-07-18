import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/geocoded_address.dart';
import 'package:maps/src/domain/entities/serving_area.dart';

/// Repository contract for geocoding operations.
///
/// Consumers depend on this contract. The concrete implementation handles
/// caching, locale management, and delegation to platform services.
abstract class GeocodingRepository {
  TaskEither<Failure, GeocodedAddress> reverseGeocode(
    LatLng position, {
    String? localeIdentifier,
  });

  TaskEither<Failure, LatLng> forwardGeocode(
    String address, {
    String? localeIdentifier,
  });

  TaskEither<Failure, List<ServingArea>> nearbyAreaNames({
    required LatLng center,
    required double radiusKm,
    String? localeIdentifier,
  });
}
