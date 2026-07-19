import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Coarse location-permission state, decoupled from any permission plugin.
enum LocationPermissionStatus {
  /// Permission is granted (or not required on this platform).
  granted,

  /// Denied but can still be requested via the normal prompt.
  denied,

  /// Blocked at the OS level — only recoverable through app settings.
  permanentlyDenied,

  /// Device location services are switched off entirely.
  serviceDisabled,
}

/// Contract for reading the device location.
abstract class LocationService {
  /// Returns the current device position as a [LatLng].
  TaskEither<Failure, LatLng> getCurrentLocation();

  /// Reads the current location-permission state without prompting or
  /// fetching a position. Cheap enough to gate UI on.
  Future<LocationPermissionStatus> checkPermission();

  /// Opens the OS app-settings screen.
  Future<bool> openAppSettings();
}
