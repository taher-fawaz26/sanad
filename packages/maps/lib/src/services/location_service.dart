import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Contract for reading the device location.
abstract class LocationService {
  /// Returns the current device position as a [LatLng].
  TaskEither<Failure, LatLng> getCurrentLocation();

  /// Opens the OS app-settings screen.
  Future<bool> openAppSettings();
}
