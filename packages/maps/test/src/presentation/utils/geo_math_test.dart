import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/presentation/utils/geo_math.dart';

void main() {
  group('GeoMath', () {
    group('distanceKm', () {
      test('returns 0 for same point', () {
        const p = LatLng(25.0, 55.0);
        expect(GeoMath.distanceKm(p, p), 0.0);
      });

      test('calculates known distance (Dubai to Abu Dhabi ~130km)', () {
        const dubai = LatLng(25.2048, 55.2708);
        const abuDhabi = LatLng(24.4539, 54.3773);
        final distance = GeoMath.distanceKm(dubai, abuDhabi);
        expect(distance, closeTo(120, 20));
      });

      test('is symmetric', () {
        const a = LatLng(25.0, 55.0);
        const b = LatLng(26.0, 56.0);
        expect(
          GeoMath.distanceKm(a, b),
          closeTo(GeoMath.distanceKm(b, a), 0.001),
        );
      });
    });

    group('offsetByKm', () {
      test('offset north increases latitude', () {
        const origin = LatLng(25.0, 55.0);
        final result = GeoMath.offsetByKm(
          origin,
          distanceKm: 10,
          bearingDegrees: 0,
        );
        expect(result.latitude, greaterThan(origin.latitude));
        expect(
          result.longitude,
          closeTo(origin.longitude, 0.01),
        );
      });

      test('offset east increases longitude', () {
        const origin = LatLng(25.0, 55.0);
        final result = GeoMath.offsetByKm(
          origin,
          distanceKm: 10,
          bearingDegrees: 90,
        );
        expect(result.longitude, greaterThan(origin.longitude));
        expect(
          result.latitude,
          closeTo(origin.latitude, 0.01),
        );
      });

      test('round-trip distance matches offset distance', () {
        const origin = LatLng(25.0, 55.0);
        final offset = GeoMath.offsetByKm(
          origin,
          distanceKm: 5,
          bearingDegrees: 45,
        );
        final distance = GeoMath.distanceKm(origin, offset);
        expect(distance, closeTo(5, 0.1));
      });
    });

    group('gridSamplePoints', () {
      test('always includes the center', () {
        const center = LatLng(25.0, 55.0);
        final points = GeoMath.gridSamplePoints(
          center,
          radiusKm: 5,
          spacingKm: 1.5,
        );
        expect(points, contains(center));
      });

      test('every generated point is within the radius', () {
        const center = LatLng(25.0, 55.0);
        const radiusKm = 5.0;
        final points = GeoMath.gridSamplePoints(
          center,
          radiusKm: radiusKm,
          spacingKm: 1.5,
        );
        for (final point in points) {
          expect(
            GeoMath.distanceKm(center, point),
            lessThanOrEqualTo(radiusKm + 0.01),
          );
        }
      });

      test('denser spacing yields more sample points for the same radius', () {
        const center = LatLng(25.0, 55.0);
        final dense = GeoMath.gridSamplePoints(
          center,
          radiusKm: 10,
          spacingKm: 1.0,
        );
        final sparse = GeoMath.gridSamplePoints(
          center,
          radiusKm: 10,
          spacingKm: 3.0,
        );
        expect(dense.length, greaterThan(sparse.length));
      });

      test('larger radius yields more sample points for the same spacing', () {
        const center = LatLng(25.0, 55.0);
        final small = GeoMath.gridSamplePoints(
          center,
          radiusKm: 3,
          spacingKm: 1.5,
        );
        final large = GeoMath.gridSamplePoints(
          center,
          radiusKm: 12,
          spacingKm: 1.5,
        );
        expect(large.length, greaterThan(small.length));
      });

      test('zero radius returns only the center', () {
        const center = LatLng(25.0, 55.0);
        final points = GeoMath.gridSamplePoints(
          center,
          radiusKm: 0,
          spacingKm: 1.5,
        );
        expect(points, [center]);
      });
    });

    group('boundsForRadius', () {
      test('produces southwest < northeast', () {
        const center = LatLng(25.0, 55.0);
        final region = GeoMath.boundsForRadius(center, 10);
        expect(
          region.southwest.latitude,
          lessThan(region.northeast.latitude),
        );
        expect(
          region.southwest.longitude,
          lessThan(region.northeast.longitude),
        );
      });

      test('center is within bounds', () {
        const center = LatLng(25.0, 55.0);
        final region = GeoMath.boundsForRadius(center, 10);
        expect(
          center.latitude,
          greaterThan(region.southwest.latitude),
        );
        expect(
          center.latitude,
          lessThan(region.northeast.latitude),
        );
      });
    });
  });
}
