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

/// Default implementation using [Geolocator] and [PermissionsService].
class LocationServiceImpl implements LocationService {
  const LocationServiceImpl(this._permissionsService);

  final PermissionsService _permissionsService;

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
  Future<bool> openAppSettings() => _permissionsService.openSettings();

  Future<LatLng> _resolveCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const _LocationServiceException(
        message: 'Location services are disabled.',
        code: LocationFailureCodes.serviceDisabled,
      );
    }

    final permissionResult = await _permissionsService.request(
      Permission.locationWhenInUse,
    );

    switch (permissionResult) {
      case PermissionRequestResult.granted:
      case PermissionRequestResult.notRequired:
        break;
      case PermissionRequestResult.denied:
        throw const _LocationServiceException(
          message: 'Location permission was denied.',
          code: LocationFailureCodes.permissionDenied,
        );
      case PermissionRequestResult.permanentlyDenied:
        throw const _LocationServiceException(
          message: 'Location permission is permanently denied.',
          code: LocationFailureCodes.permissionPermanentlyDenied,
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
