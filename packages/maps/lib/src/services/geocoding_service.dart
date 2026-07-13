import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Contract for forward and reverse geocoding.
abstract class GeocodingService {
  /// Converts [position] into a human-readable address string.
  TaskEither<Failure, String> addressFromCoordinates(LatLng position);

  /// Converts [address] into map coordinates.
  TaskEither<Failure, LatLng> coordinatesFromAddress(String address);
}
