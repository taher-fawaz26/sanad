import 'dart:math' as math;

import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/geocoded_address.dart';
import 'package:maps/src/domain/entities/serving_area.dart';
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
  TaskEither<Failure, GeocodedAddress> addressFromCoordinates(
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
        final placemark = placemarks.first;
        final iso = placemark.isoCountryCode;
        return GeocodedAddress(
          formattedAddress: _formatPlacemark(placemark),
          areaName: _areaNameFromPlacemark(placemark),
          isoCountryCode: (iso == null || iso.isEmpty)
              ? null
              : iso.toUpperCase(),
        );
      },
      (error, _) => LocationFailure(
        message: _failureMessage(error),
        code: LocationFailureCodes.geocodingFailed,
      ),
    );
  }

  /// Never surface the raw platform exception text (e.g.
  /// `PlatformException(NOT_FOUND, ...)`) — callers localize by the failure
  /// code, and any code path that still reads `.message` gets a stable,
  /// non-leaking sentence (SAN-778).
  static String _failureMessage(Object error) => error is _GeocodingException
      ? error.message
      : 'Failed to resolve the address for the selected location.';

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
        message: _failureMessage(error),
        code: LocationFailureCodes.geocodingFailed,
      ),
    );
  }

  @override
  TaskEither<Failure, List<ServingArea>> nearbyAreaNames({
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
        final resolved = await Future.wait(samplePoints.map(_areaAt));

        // Deduplicate by name, keeping the first occurrence's coordinates so
        // each ServingArea carries a stable coordinate-based place ID.
        final seenNames = <String>{};
        final areas = <ServingArea>[];
        for (final entry in resolved) {
          if (entry == null) continue;
          final (point, name) = entry;
          if (!seenNames.add(name)) continue;
          areas.add(
            ServingArea(
              placeId: _coordinateKey(point),
              name: name,
              address: '',
              latLng: point,
            ),
          );
        }

        return areas;
      },
      (error, _) => LocationFailure(
        message: _failureMessage(error),
        code: LocationFailureCodes.geocodingFailed,
      ),
    );
  }

  /// Reverse-geocodes a single [point] to a (position, name) pair, swallowing
  /// errors so callers can sample many points without one failure aborting the
  /// batch. Returns null when no area name can be resolved for the point.
  Future<(LatLng, String)?> _areaAt(LatLng point) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (placemarks.isEmpty) return null;
      final name = _areaNameFromPlacemark(placemarks.first);
      if (name == null || name.isEmpty) return null;
      return (point, name);
    } on Exception {
      return null;
    }
  }

  static String _coordinateKey(LatLng position) =>
      'latlng:${position.latitude},${position.longitude}';

  /// Picks the best human-friendly area name from a placemark, preferring the
  /// most local, neighborhood-like value and falling back outward.
  ///
  /// Priority: neighborhood/sub-locality → locality → sub-administrative area →
  /// administrative area → place name. Returns null when none are present, in
  /// which case callers fall back to the full formatted address.
  String? _areaNameFromPlacemark(Placemark placemark) {
    final candidates = <String?>[
      placemark.subLocality,
      placemark.locality,
      placemark.subAdministrativeArea,
      placemark.administrativeArea,
      placemark.name,
    ];
    for (final value in candidates) {
      if (value != null && value.isNotEmpty) return value;
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
    final newLng =
        lngRad +
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
