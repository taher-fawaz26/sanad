import 'dart:async';

import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/services/location_failure_codes.dart';
import 'package:maps/src/services/location_service.dart';
import 'package:permissions/permissions.dart';

class _LocationServiceException implements Exception {
  const _LocationServiceException({
    required this.message,
    required this.code,
  });

  final String message;
  final String code;

  @override
  String toString() => message;
}

/// Default implementation using [Geolocator] and [PermissionService].
class LocationServiceImpl implements LocationService {
  const LocationServiceImpl(this._permissionService);

  final PermissionService _permissionService;

  @override
  TaskEither<Failure, LatLng> getCurrentLocation() {
    return TaskEither.tryCatch(
      _resolveCurrentLocation,
      (error, _) {
        if (error is _LocationServiceException) {
          return LocationFailure(
            message: error.message,
            code: error.code,
          );
        }
        // Never leak a raw platform exception string to the UI — callers
        // localize by [code] only. Map the well-known Geolocator/async
        // failures to stable codes; anything else is a generic
        // [unavailable] (SAN-778).
        return LocationFailure(
          message: 'Failed to resolve the current location.',
          code: _codeForError(error),
        );
      },
    );
  }

  static String _codeForError(Object error) {
    if (error is TimeoutException) return LocationFailureCodes.timeout;
    if (error is LocationServiceDisabledException) {
      return LocationFailureCodes.serviceDisabled;
    }
    if (error is PermissionDeniedException) {
      return LocationFailureCodes.permissionDenied;
    }
    return LocationFailureCodes.unavailable;
  }

  @override
  Future<LocationPermissionStatus> checkPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationPermissionStatus.serviceDisabled;

    final result = await _permissionService.check(
      PermissionType.locationWhenInUse,
    );

    return _toLocationPermissionStatus(result);
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    // Request the app permission FIRST so the OS prompt appears even when
    // device location services are currently off — otherwise tapping
    // "use my current location" while location is disabled does nothing and
    // never surfaces the permission dialog (SAN-778). The service-enabled
    // check comes after, so a granted-but-disabled state still reports
    // [serviceDisabled].
    final result = await _permissionService.request(
      PermissionType.locationWhenInUse,
    );
    final status = _toLocationPermissionStatus(result);
    if (status != LocationPermissionStatus.granted) return status;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationPermissionStatus.serviceDisabled;

    return LocationPermissionStatus.granted;
  }

  @override
  Future<bool> openAppSettings() => _permissionService.openSettings();

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  LocationPermissionStatus _toLocationPermissionStatus(
    PermissionResult result,
  ) {
    if (result.isGranted) return LocationPermissionStatus.granted;
    // permanentlyDenied || restricted — only recoverable via app settings.
    if (result.canOpenSettings) {
      return LocationPermissionStatus.permanentlyDenied;
    }
    return LocationPermissionStatus.denied;
  }

  Future<LatLng> _resolveCurrentLocation() async {
    // Request permission FIRST (before checking whether device location
    // services are enabled) so the native permission prompt reliably appears
    // on the first tap, even when location services are currently off — the
    // previous service-first ordering returned early and never prompted
    // (SAN-778).
    final result = await _permissionService.request(
      PermissionType.locationWhenInUse,
    );

    if (!result.isGranted) {
      if (result.canOpenSettings) {
        throw const _LocationServiceException(
          message: 'Location permission is permanently denied.',
          code: LocationFailureCodes.permissionPermanentlyDenied,
        );
      }
      throw const _LocationServiceException(
        message: 'Location permission was denied.',
        code: LocationFailureCodes.permissionDenied,
      );
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const _LocationServiceException(
        message: 'Location services are disabled.',
        code: LocationFailureCodes.serviceDisabled,
      );
    }

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 15),
    );

    final position = await Geolocator.getCurrentPosition(
      locationSettings: settings,
    );

    return LatLng(position.latitude, position.longitude);
  }
}
