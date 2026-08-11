import 'package:branches/src/presentation/models/coverage_area_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/maps.dart';

void main() {
  const _center = LatLng(25.0, 55.0);

  const _autoA = ServingArea(
    placeId: 'latlng:25.0,55.0',
    name: 'Dubai Marina',
    address: '',
    latLng: _center,
  );

  const _autoB = ServingArea(
    placeId: 'latlng:25.1,55.1',
    name: 'JBR',
    address: '',
    latLng: LatLng(25.1, 55.1),
  );

  const _extraA = ServingArea(
    placeId: 'ChIJLU7jZClu5kcR4PcOOO6p3I0',
    name: 'Palm Jumeirah',
    address: 'Palm Jumeirah, Dubai, UAE',
    latLng: LatLng(25.1, 55.15),
  );

  const _result = CoverageAreaResult(
    position: _center,
    address: 'Dubai Marina, Dubai',
    radiusKm: 5,
    autoAreas: [_autoA, _autoB],
    extraAreas: [_extraA],
  );

  group('CoverageAreaResult.servingAreas', () {
    test('combines auto and extra areas in order', () {
      expect(_result.servingAreas, [_autoA, _autoB, _extraA]);
    });

    test('empty when no areas', () {
      const empty = CoverageAreaResult(
        position: _center,
        address: 'addr',
        radiusKm: 1,
      );
      expect(empty.servingAreas, isEmpty);
    });

    test('displays area names — not place IDs — for auto areas', () {
      for (final area in _result.autoAreas) {
        expect(area.name, isNot(contains('latlng:')));
      }
    });
  });

  group('CoverageAreaResult.servingAreaPlaceIds', () {
    test('uses placeId from auto areas, not their display names', () {
      final ids = _result.servingAreaPlaceIds;
      expect(ids, contains('latlng:25.0,55.0'));
      expect(ids, contains('latlng:25.1,55.1'));
      expect(ids, isNot(contains('Dubai Marina')));
      expect(ids, isNot(contains('JBR')));
    });

    test('preserves real Google Place ID from extra area', () {
      final ids = _result.servingAreaPlaceIds;
      expect(ids, contains('ChIJLU7jZClu5kcR4PcOOO6p3I0'));
    });

    test('produces [autoIds..., extraIds...] in order', () {
      expect(_result.servingAreaPlaceIds, [
        'latlng:25.0,55.0',
        'latlng:25.1,55.1',
        'ChIJLU7jZClu5kcR4PcOOO6p3I0',
      ]);
    });

    test('empty when no areas', () {
      const empty = CoverageAreaResult(
        position: _center,
        address: 'addr',
        radiusKm: 1,
      );
      expect(empty.servingAreaPlaceIds, isEmpty);
    });
  });

  group('CoverageAreaResult equality', () {
    test('equal instances with same data', () {
      const a = CoverageAreaResult(
        position: _center,
        address: 'addr',
        radiusKm: 5,
        autoAreas: [_autoA],
        extraAreas: [_extraA],
      );
      const b = CoverageAreaResult(
        position: _center,
        address: 'addr',
        radiusKm: 5,
        autoAreas: [_autoA],
        extraAreas: [_extraA],
      );
      expect(a, equals(b));
    });
  });
}
