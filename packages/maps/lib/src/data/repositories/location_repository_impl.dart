import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/repositories/location_repository.dart';
import 'package:maps/src/services/location_service.dart';

/// [LocationRepository] backed by [LocationService].
class LocationRepositoryImpl implements LocationRepository {
  const LocationRepositoryImpl(this._service);

  final LocationService _service;

  @override
  TaskEither<Failure, LatLng> getCurrentLocation() =>
      _service.getCurrentLocation();

  @override
  Future<bool> openAppSettings() => _service.openAppSettings();

  @override
  Future<bool> openLocationSettings() => _service.openLocationSettings();

  @override
  Future<LocationPermissionStatus> checkPermission() =>
      _service.checkPermission();
}
