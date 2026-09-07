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

  /// Triggers the native OS permission prompt (when the OS still allows
  /// asking) and returns the resulting state. Checks the location service
  /// first, same as [checkPermission].
  Future<LocationPermissionStatus> requestPermission();

  /// Opens the OS app-settings screen. Recovery path when the app permission
  /// is permanently denied.
  Future<bool> openAppSettings();

  /// Opens the OS *device location* settings screen (the global GPS toggle).
  /// Recovery path when location services are switched off — distinct from
  /// [openAppSettings], which only exposes the app's own permission and cannot
  /// turn the device radio on.
  Future<bool> openLocationSettings();
}
