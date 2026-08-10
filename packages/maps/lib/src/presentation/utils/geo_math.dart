import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/map_region.dart';

/// Pure geographic math utilities.
abstract final class GeoMath {
  GeoMath._();

  static const _earthRadiusKm = 6371.0;
  static const _kmPerDegree = 111.32;

  /// Offsets [origin] by [distanceKm] in [bearingDegrees] (0 = north).
  static LatLng offsetByKm(
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

    return LatLng(
      newLat * 180 / math.pi,
      newLng * 180 / math.pi,
    );
  }

  /// Returns a bounding [MapRegion] around [center] with [radiusKm].
  static MapRegion boundsForRadius(LatLng center, double radiusKm) {
    final offset = radiusKm / _kmPerDegree;
    return MapRegion(
      southwest: LatLng(
        center.latitude - offset,
        center.longitude - offset,
      ),
      northeast: LatLng(
        center.latitude + offset,
        center.longitude + offset,
      ),
    );
  }

  /// Generates a square-lattice grid of sample points covering the circle of
  /// [radiusKm] around [center], spaced [spacingKm] apart, keeping only
  /// points within the circle (plus [center] itself, always included).
  ///
  /// Used to sample a bounded area for reverse-geocode area discovery, since
  /// no Google API can enumerate geographic areas within a radius directly.
  static List<LatLng> gridSamplePoints(
    LatLng center, {
    required double radiusKm,
    required double spacingKm,
  }) {
    if (radiusKm <= 0 || spacingKm <= 0) return [center];

    final points = <LatLng>[center];
    final steps = (radiusKm / spacingKm).ceil();

    for (var i = -steps; i <= steps; i++) {
      for (var j = -steps; j <= steps; j++) {
        if (i == 0 && j == 0) continue;
        final north = i * spacingKm;
        final east = j * spacingKm;
        final point = _offsetByKmComponents(
          center,
          northKm: north,
          eastKm: east,
        );
        if (distanceKm(center, point) <= radiusKm) {
          points.add(point);
        }
      }
    }
    return points;
  }

  /// Offsets [origin] by independent north/east components in km. Equivalent
  /// to a local planar approximation, accurate enough at neighborhood scale.
  static LatLng _offsetByKmComponents(
    LatLng origin, {
    required double northKm,
    required double eastKm,
  }) {
    final latRad = origin.latitude * math.pi / 180;
    final newLat = origin.latitude + (northKm / _kmPerDegree);
    final kmPerDegreeLng = _kmPerDegree * math.cos(latRad);
    final newLng = kmPerDegreeLng == 0
        ? origin.longitude
        : origin.longitude + (eastKm / kmPerDegreeLng);
    return LatLng(newLat, newLng);
  }

  /// Haversine distance between two points in km.
  static double distanceKm(LatLng a, LatLng b) {
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final aLat = a.latitude * math.pi / 180;
    final bLat = b.latitude * math.pi / 180;

    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(aLat) *
            math.cos(bLat) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * _earthRadiusKm * math.asin(math.sqrt(h));
  }
}
