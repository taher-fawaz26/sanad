import 'package:branches/src/presentation/utils/serving_area_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';

void main() {
  group('servingAreaFromPickerResult', () {
    test('uses the real Google place id when present', () {
      final area = servingAreaFromPickerResult(
        const MapAreaPickerResult(
          placeId: 'ChIJ_real_place',
          areaName: 'Dubai Marina',
          address: 'Dubai Marina, Dubai',
          position: LatLng(25.0, 55.0),
        ),
      );

      expect(area, isNotNull);
      expect(area!.placeId, 'ChIJ_real_place');
      expect(area.name, 'Dubai Marina');
    });

    test('returns null when place id is absent', () {
      final area = servingAreaFromPickerResult(
        const MapAreaPickerResult(
          areaName: 'Dropped pin',
          address: 'Dubai Marina, Dubai',
          position: LatLng(25.0, 55.0),
        ),
      );

      expect(area, isNull);
    });

    test('never generates synthetic latlng: ids', () {
      final withId = servingAreaFromPickerResult(
        const MapAreaPickerResult(
          placeId: 'ChIJ_real',
          areaName: 'Area',
          address: 'Address',
          position: LatLng(25.0, 55.0),
        ),
      );
      final withoutId = servingAreaFromPickerResult(
        const MapAreaPickerResult(
          areaName: 'Area',
          address: 'Address',
          position: LatLng(25.0, 55.0),
        ),
      );

      expect(withId!.placeId.startsWith('latlng:'), isFalse);
      expect(withoutId, isNull);
    });
  });
}
