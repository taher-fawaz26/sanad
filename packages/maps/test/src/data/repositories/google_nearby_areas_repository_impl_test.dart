import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/data/repositories/google_nearby_areas_repository_impl.dart';
import 'package:maps/src/domain/failures/places_failure.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late GoogleNearbyAreasRepositoryImpl repository;

  const center = LatLng(25.2048, 55.2708);

  Response<Map<String, dynamic>> buildResponse(Map<String, dynamic> body) =>
      Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: 'geocode'),
        statusCode: 200,
        data: body,
      );

  /// A single geocoding result for a UAE neighborhood.
  Map<String, dynamic> uaeResult({
    required String placeId,
    required String name,
    required double lat,
    required double lng,
  }) => {
    'place_id': placeId,
    'formatted_address': '$name, Dubai',
    'geometry': {
      'location': {'lat': lat, 'lng': lng},
    },
    'address_components': [
      {
        'long_name': name,
        'short_name': name,
        'types': ['neighborhood', 'political'],
      },
      {
        'long_name': 'United Arab Emirates',
        'short_name': 'AE',
        'types': ['country', 'political'],
      },
    ],
    'types': ['neighborhood', 'political'],
  };

  void stubAll(Map<String, dynamic> body) {
    when(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer((_) async => buildResponse(body));
  }

  setUp(() {
    dio = _MockDio();
    repository = GoogleNearbyAreasRepositoryImpl(apiKey: 'key', dio: dio);
  });

  group('GoogleNearbyAreasRepositoryImpl.resolveNearbyAreas', () {
    test('parses UAE neighborhoods and dedupes across sample points', () async {
      stubAll({
        'status': 'OK',
        'results': [
          uaeResult(
            placeId: 'ChIJ_marina',
            name: 'Dubai Marina',
            lat: 25.205,
            lng: 55.271,
          ),
        ],
      });

      final result = await repository
          .resolveNearbyAreas(center: center, radiusKm: 5)
          .run();

      final areas = result.getOrElse((_) => []);
      // Every sample returns the same place → deduped to one.
      expect(areas, hasLength(1));
      expect(areas.single.placeId, 'ChIJ_marina');
      expect(areas.single.name, 'Dubai Marina');
    });

    test('drops results outside the target country', () async {
      stubAll({
        'status': 'OK',
        'results': [
          {
            'place_id': 'ChIJ_abroad',
            'formatted_address': 'Somewhere, KSA',
            'geometry': {
              'location': {'lat': 25.205, 'lng': 55.271},
            },
            'address_components': [
              {
                'long_name': 'Some Area',
                'short_name': 'Some Area',
                'types': ['neighborhood', 'political'],
              },
              {
                'long_name': 'Saudi Arabia',
                'short_name': 'SA',
                'types': ['country', 'political'],
              },
            ],
            'types': ['neighborhood', 'political'],
          },
        ],
      });

      final result = await repository
          .resolveNearbyAreas(center: center, radiusKm: 5)
          .run();

      expect(result.getOrElse((_) => []), isEmpty);
    });

    test('drops areas whose centroid is beyond the radius', () async {
      stubAll({
        'status': 'OK',
        'results': [
          uaeResult(
            placeId: 'ChIJ_far',
            name: 'Far Area',
            lat: 26.5,
            lng: 56.5,
          ),
        ],
      });

      final result = await repository
          .resolveNearbyAreas(center: center, radiusKm: 1)
          .run();

      expect(result.getOrElse((_) => []), isEmpty);
    });

    test('normalizes locale to a language subtag for Google', () async {
      stubAll({'status': 'ZERO_RESULTS', 'results': <dynamic>[]});

      await repository
          .resolveNearbyAreas(
            center: center,
            radiusKm: 5,
            languageCode: 'ar_AE',
          )
          .run();

      final captured = verify(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: captureAny(named: 'queryParameters'),
        ),
      ).captured;
      final params = captured.first as Map<String, dynamic>;
      expect(params['language'], 'ar');
      expect(params['result_type'], 'neighborhood|sublocality');
      expect(params['region'], 'ae');
    });

    test('surfaces a failure when every sample errors', () async {
      stubAll({
        'status': 'REQUEST_DENIED',
        'error_message': 'bad key',
      });

      final result = await repository
          .resolveNearbyAreas(center: center, radiusKm: 5)
          .run();

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) => expect(failure, isA<PlacesApiKeyFailure>()),
        (_) => fail('expected a failure'),
      );
    });
  });
}
