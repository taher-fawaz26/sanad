import 'dart:math' as math;

import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/services/geocoding_service.dart';
import 'package:maps/src/services/location_failure_codes.dart';

class _GeocodingException implements Exception {
  const _GeocodingException({required this.message});

  final String message;

  @override
  String toString() => message;
}

/// Default implementation using the platform geocoding plugin.
class GeocodingServiceImpl implements GeocodingService {
  const GeocodingServiceImpl();

  static const _earthRadiusKm = 6371.0;

  /// Number of points sampled around the coverage circle (plus the center).
  static const _sampleBearingCount = 8;

  /// Fraction of the coverage radius at which the ring is sampled.
  static const _sampleRadiusFactor = 0.65;

  /// Lower bound for the sampling ring so tiny radii still hit nearby areas.
  static const _minSampleRadiusKm = 0.5;

  @override
  TaskEither<Failure, String> addressFromCoordinates(
    LatLng position, {
    String? localeIdentifier,
  }) {
    return TaskEither.tryCatch(
      () async {
        if (localeIdentifier != null) {
          await setLocaleIdentifier(localeIdentifier);
        }
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isEmpty) {
          throw const _GeocodingException(
            message: 'No address found for the selected location.',
          );
        }
        return _formatPlacemark(placemarks.first);
      },
      (error, _) => LocationFailure(
        message: error.toString(),
        code: LocationFailureCodes.geocodingFailed,
      ),
    );
  }

  @override
  TaskEither<Failure, LatLng> coordinatesFromAddress(
    String address, {
    String? localeIdentifier,
  }) {
    return TaskEither.tryCatch(
      () async {
        final trimmed = address.trim();
        if (trimmed.isEmpty) {
          throw const _GeocodingException(
            message: 'Search query cannot be empty.',
          );
        }

        if (localeIdentifier != null) {
          await setLocaleIdentifier(localeIdentifier);
        }
        final locations = await locationFromAddress(trimmed);
        if (locations.isEmpty) {
          throw const _GeocodingException(
            message: 'No location found for the search query.',
          );
        }

        final location = locations.first;
        return LatLng(location.latitude, location.longitude);
      },
      (error, _) => LocationFailure(
        message: error.toString(),
        code: LocationFailureCodes.geocodingFailed,
      ),
    );
  }

  @override
  TaskEither<Failure, List<String>> nearbyAreaNames({
    required LatLng center,
    required double radiusKm,
    String? localeIdentifier,
  }) {
    return TaskEither.tryCatch(
      () async {
        if (localeIdentifier != null) {
          await setLocaleIdentifier(localeIdentifier);
        }

        final sampleRadius = math.max(
          radiusKm * _sampleRadiusFactor,
          _minSampleRadiusKm,
        );
        const bearingStep = 360 / _sampleBearingCount;
        final samplePoints = <LatLng>[
          center,
          for (var i = 0; i < _sampleBearingCount; i++)
            _offsetByKm(
              center,
              distanceKm: sampleRadius,
              bearingDegrees: i * bearingStep,
            ),
        ];

        // Sample concurrently; individual failures are tolerated so a single
        // throttled lookup doesn't discard every other resolved area.
        final resolved = await Future.wait(samplePoints.map(_areaNameAt));

        final names = <String>{
          for (final name in resolved)
            if (name != null && name.isNotEmpty) name,
        };

        return names.toList(growable: false);
      },
      (error, _) => LocationFailure(
        message: error.toString(),
        code: LocationFailureCodes.geocodingFailed,
      ),
    );
  }

  /// Reverse-geocodes a single [point] to an area name, swallowing errors so
  /// callers can sample many points without one failure aborting the batch.
  Future<String?> _areaNameAt(LatLng point) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (placemarks.isEmpty) return null;
      return _areaNameFromPlacemark(placemarks.first);
    } on Exception {
      return null;
    }
  }

  String? _areaNameFromPlacemark(Placemark placemark) {
    if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
      return placemark.subLocality;
    }
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      return placemark.locality;
    }
    if (placemark.administrativeArea != null &&
        placemark.administrativeArea!.isNotEmpty) {
      return placemark.administrativeArea;
    }
    return null;
  }

  LatLng _offsetByKm(
    LatLng origin, {
    required double distanceKm,
    required double bearingDegrees,
  }) {
    final bearingRad = bearingDegrees * math.pi / 180;
    final latRad = origin.latitude * math.pi / 180;
    final lngRad = origin.longitude * math.pi / 180;
    final angularDistance = distanceKm / _earthRadiusKm;

    final newLat = math.asin(
      math.sin(latRad) * math.cos(angularDistance) +
          math.cos(latRad) * math.sin(angularDistance) * math.cos(bearingRad),
    );
    final newLng = lngRad +
        math.atan2(
          math.sin(bearingRad) * math.sin(angularDistance) * math.cos(latRad),
          math.cos(angularDistance) - math.sin(latRad) * math.sin(newLat),
        );

    return LatLng(newLat * 180 / math.pi, newLng * 180 / math.pi);
  }

  String _formatPlacemark(Placemark placemark) {
    final parts = <String>[
      if (placemark.name != null && placemark.name!.isNotEmpty) placemark.name!,
      if (placemark.street != null && placemark.street!.isNotEmpty)
        placemark.street!,
      if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty)
        placemark.subLocality!,
      if (placemark.locality != null && placemark.locality!.isNotEmpty)
        placemark.locality!,
      if (placemark.administrativeArea != null &&
          placemark.administrativeArea!.isNotEmpty)
        placemark.administrativeArea!,
      if (placemark.country != null && placemark.country!.isNotEmpty)
        placemark.country!,
    ];

    final uniqueParts = <String>[];
    for (final part in parts) {
      if (!uniqueParts.contains(part)) {
        uniqueParts.add(part);
      }
    }

    return uniqueParts.join(', ');
  }
}
