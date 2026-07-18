import 'package:flutter_test/flutter_test.dart';
import 'package:maps/src/data/models/area_dto.dart';

void main() {
  group('AreaDto', () {
    final json = <String, dynamic>{
      'id': 'area-uuid-1',
      'placeId': 'ChIJ3QPOgqjK9T4R3KMk0f9ucsg',
      'nameEn': 'Al Barsha',
      'nameAr': 'البرشاء',
      'latitude': 25.0987,
      'longitude': 55.1956,
      'cityId': 'city-uuid-1',
      'countryId': 'country-uuid-1',
    };

    test('fromJson parses all fields correctly', () {
      final dto = AreaDto.fromJson(json);
      expect(dto.id, 'area-uuid-1');
      expect(dto.placeId, 'ChIJ3QPOgqjK9T4R3KMk0f9ucsg');
      expect(dto.nameEn, 'Al Barsha');
      expect(dto.nameAr, 'البرشاء');
      expect(dto.latitude, 25.0987);
      expect(dto.longitude, 55.1956);
      expect(dto.cityId, 'city-uuid-1');
      expect(dto.countryId, 'country-uuid-1');
    });

    test('fromJson handles integer latitude/longitude', () {
      final intJson = {...json, 'latitude': 25, 'longitude': 55};
      final dto = AreaDto.fromJson(intJson);
      expect(dto.latitude, 25.0);
      expect(dto.longitude, 55.0);
    });

    test('toDomain maps all fields to AreaEntity', () {
      final entity = AreaDto.fromJson(json).toDomain();
      expect(entity.id, 'area-uuid-1');
      expect(entity.placeId, 'ChIJ3QPOgqjK9T4R3KMk0f9ucsg');
      expect(entity.nameEn, 'Al Barsha');
      expect(entity.nameAr, 'البرشاء');
      expect(entity.latitude, 25.0987);
      expect(entity.longitude, 55.1956);
      expect(entity.cityId, 'city-uuid-1');
      expect(entity.countryId, 'country-uuid-1');
    });
  });
}
