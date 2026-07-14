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

      expect(area.placeId, 'ChIJ_real_place');
      expect(area.name, 'Dubai Marina');
    });

    test('derives id from coordinates (not address) when place id is null', () {
      final area = servingAreaFromPickerResult(
        const MapAreaPickerResult(
          areaName: 'Dropped pin',
          address: 'Dubai Marina, Dubai',
          position: LatLng(25.0, 55.0),
        ),
      );

      expect(area.placeId, isNot('Dubai Marina, Dubai'));
      expect(area.placeId, contains('25.0'));
      expect(area.placeId, contains('55.0'));
    });

    test(
      'two map-tapped picks with the same address but different coordinates '
      'produce distinct ids (regression: BUG 1 dedup collision)',
      () {
        final first = servingAreaFromPickerResult(
          const MapAreaPickerResult(
            areaName: 'Dubai Marina',
            address: 'Dubai Marina, Dubai',
            position: LatLng(25.0, 55.0),
          ),
        );
        final second = servingAreaFromPickerResult(
          const MapAreaPickerResult(
            areaName: 'Dubai Marina',
            address: 'Dubai Marina, Dubai',
            position: LatLng(25.05, 55.05),
          ),
        );

        expect(first.placeId, isNot(second.placeId));
        expect(first == second, isFalse);
      },
    );
  });
}
