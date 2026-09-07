import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/services/location_service.dart';

/// Repository contract for device location operations.
abstract class LocationRepository {
  TaskEither<Failure, LatLng> getCurrentLocation();

  Future<bool> openAppSettings();

  /// Opens the OS device-location settings (the global GPS toggle). Recovery
  /// path when location services are disabled.
  Future<bool> openLocationSettings();

  /// Reads the current location-permission state without prompting or
  /// fetching a position. Cheap enough to gate UI on.
  Future<LocationPermissionStatus> checkPermission();
}
