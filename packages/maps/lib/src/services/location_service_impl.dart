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
        return LocationFailure(
          message: error.toString(),
          code: LocationFailureCodes.unavailable,
        );
      },
    );
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
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationPermissionStatus.serviceDisabled;

    final result = await _permissionService.request(
      PermissionType.locationWhenInUse,
    );

    return _toLocationPermissionStatus(result);
  }

  @override
  Future<bool> openAppSettings() => _permissionService.openSettings();

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
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const _LocationServiceException(
        message: 'Location services are disabled.',
        code: LocationFailureCodes.serviceDisabled,
      );
    }

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
