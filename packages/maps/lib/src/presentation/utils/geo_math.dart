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
          math.cos(latRad) *
              math.sin(angularDistance) *
              math.cos(bearingRad),
    );
    final newLng = lngRad +
        math.atan2(
          math.sin(bearingRad) *
              math.sin(angularDistance) *
              math.cos(latRad),
          math.cos(angularDistance) -
              math.sin(latRad) * math.sin(newLat),
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

  /// Haversine distance between two points in km.
  static double distanceKm(LatLng a, LatLng b) {
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final aLat = a.latitude * math.pi / 180;
    final bLat = b.latitude * math.pi / 180;

    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(aLat) *
            math.cos(bLat) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * _earthRadiusKm * math.asin(math.sqrt(h));
  }
}
