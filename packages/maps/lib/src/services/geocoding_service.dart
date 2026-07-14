import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/geocoded_address.dart';

/// Contract for forward and reverse geocoding.
abstract class GeocodingService {
  /// Converts [position] into a [GeocodedAddress] carrying both the full
  /// formatted address and a human-friendly area name.
  ///
  /// [localeIdentifier] (e.g. `en_US`, `ar_AE`) formats/translates the
  /// result to match the app's current language, instead of the device's
  /// system locale.
  TaskEither<Failure, GeocodedAddress> addressFromCoordinates(
    LatLng position, {
    String? localeIdentifier,
  });

  /// Converts [address] into map coordinates.
  TaskEither<Failure, LatLng> coordinatesFromAddress(
    String address, {
    String? localeIdentifier,
  });

  /// Resolves nearby area/locality names around [center] within [radiusKm].
  ///
  /// Uses reverse geocoding of the center and sample points on the coverage
  /// circle (Google / Apple platform geocoders).
  TaskEither<Failure, List<String>> nearbyAreaNames({
    required LatLng center,
    required double radiusKm,
    String? localeIdentifier,
  });
}
