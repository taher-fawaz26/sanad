import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Repository contract for device location operations.
abstract class LocationRepository {
  TaskEither<Failure, LatLng> getCurrentLocation();

  Future<bool> openAppSettings();
}
