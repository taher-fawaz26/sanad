import 'package:flutter_test/flutter_test.dart';
import 'package:maps/src/data/models/area_dto.dart';

void main() {
  group('AreaDto parsing from paginated response', () {
    Map<String, dynamic> areaJson(String id, String placeId) => {
      'id': id,
      'placeId': placeId,
      'nameEn': 'Area $id',
      'nameAr': 'منطقة $id',
      'latitude': 25.0,
      'longitude': 55.0,
      'cityId': 'city-1',
      'countryId': 'country-1',
    };

    Map<String, dynamic> pageResponse({
      required List<Map<String, dynamic>> data,
      required int currentPage,
      required int totalPages,
    }) => {
      'data': data,
      'meta': {
        'currentPage': currentPage,
        'totalPages': totalPages,
        'totalItems': data.length,
        'itemCount': data.length,
        'itemsPerPage': 100,
      },
    };

    test('parses areas from response data array', () {
      final response = pageResponse(
        data: [
          areaJson('a1', 'ChIJ_place_1'),
          areaJson('a2', 'ChIJ_place_2'),
        ],
        currentPage: 1,
        totalPages: 1,
      );

      final items = (response['data'] as List<dynamic>)
          .map((e) => AreaDto.fromJson(e as Map<String, dynamic>).toDomain())
          .toList();

      expect(items.length, 2);
      expect(items[0].placeId, 'ChIJ_place_1');
      expect(items[1].placeId, 'ChIJ_place_2');
    });

    test('meta indicates hasMore when currentPage < totalPages', () {
      final response = pageResponse(
        data: [areaJson('a1', 'ChIJ_1')],
        currentPage: 1,
        totalPages: 3,
      );

      final meta = response['meta'] as Map<String, dynamic>;
      final currentPage = meta['currentPage'] as int;
      final totalPages = meta['totalPages'] as int;
      expect(currentPage < totalPages, isTrue);
    });

    test('meta indicates no more when currentPage == totalPages', () {
      final response = pageResponse(
        data: [areaJson('a1', 'ChIJ_1')],
        currentPage: 2,
        totalPages: 2,
      );

      final meta = response['meta'] as Map<String, dynamic>;
      final currentPage = meta['currentPage'] as int;
      final totalPages = meta['totalPages'] as int;
      expect(currentPage < totalPages, isFalse);
    });

    test('no parsed placeId contains latlng: prefix', () {
      final response = pageResponse(
        data: [
          areaJson('a1', 'ChIJ_real_place_id'),
          areaJson('a2', 'ChIJ_another_real_id'),
        ],
        currentPage: 1,
        totalPages: 1,
      );

      final items = (response['data'] as List<dynamic>)
          .map((e) => AreaDto.fromJson(e as Map<String, dynamic>).toDomain())
          .toList();

      for (final area in items) {
        expect(area.placeId.startsWith('latlng:'), isFalse);
      }
    });
  });
}
