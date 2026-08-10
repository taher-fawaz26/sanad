import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/data/repositories/google_nearby_areas_repository_impl.dart';
import 'package:maps/src/domain/failures/places_failure.dart';
import 'package:maps/src/domain/repositories/nearby_areas_repository.dart';
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
    String type = 'neighborhood',
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
        'types': [type, 'political'],
      },
      {
        'long_name': 'United Arab Emirates',
        'short_name': 'AE',
        'types': ['country', 'political'],
      },
    ],
    'types': [type, 'political'],
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

      final discovery = result.getOrElse(
        (_) => const NearbyAreasResult(areas: []),
      );
      // Every sample returns the same place -> deduped to one.
      expect(discovery.areas, hasLength(1));
      expect(discovery.areas.single.placeId, 'ChIJ_marina');
      expect(discovery.areas.single.name, 'Dubai Marina');
      expect(discovery.hadPartialFailure, isFalse);
      // Raw legacy place_id, never Places-API-New's "places/" resource name.
      expect(discovery.areas.single.placeId, isNot(startsWith('places/')));
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

      expect(
        result.getOrElse((_) => const NearbyAreasResult(areas: [])).areas,
        isEmpty,
      );
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

      expect(
        result.getOrElse((_) => const NearbyAreasResult(areas: [])).areas,
        isEmpty,
      );
    });

    test('filters to neighborhood/sublocality/sublocality_level_1 types '
        'and excludes locality', () async {
      stubAll({'status': 'ZERO_RESULTS', 'results': <dynamic>[]});

      await repository.resolveNearbyAreas(center: center, radiusKm: 1).run();

      final captured = verify(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: captureAny(named: 'queryParameters'),
        ),
      ).captured;
      final params = captured.first as Map<String, dynamic>;
      final types = (params['result_type'] as String).split('|');
      expect(
        types,
        unorderedEquals(['neighborhood', 'sublocality', 'sublocality_level_1']),
      );
      expect(types, isNot(contains('locality')));
      expect(types, isNot(contains('administrative_area_level_1')));
    });

    test('normalizes locale to a language subtag for Google', () async {
      stubAll({'status': 'ZERO_RESULTS', 'results': <dynamic>[]});

      await repository
          .resolveNearbyAreas(
            center: center,
            radiusKm: 1,
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
      expect(params['region'], 'ae');
    });

    test('normalizes en-US to the en subtag', () async {
      stubAll({'status': 'ZERO_RESULTS', 'results': <dynamic>[]});

      await repository
          .resolveNearbyAreas(
            center: center,
            radiusKm: 1,
            languageCode: 'en-US',
          )
          .run();

      final captured = verify(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: captureAny(named: 'queryParameters'),
        ),
      ).captured;
      final params = captured.first as Map<String, dynamic>;
      expect(params['language'], 'en');
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

    test('keeps successful samples and reports hadPartialFailure when some '
        'samples fail but others succeed', () async {
      var call = 0;
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async {
        call++;
        // First sample (center) succeeds; every other sample errors.
        if (call == 1) {
          return buildResponse({
            'status': 'OK',
            'results': [
              uaeResult(
                placeId: 'ChIJ_ok',
                name: 'OK Area',
                lat: center.latitude,
                lng: center.longitude,
              ),
            ],
          });
        }
        return buildResponse({
          'status': 'UNKNOWN_ERROR',
          'error_message': 'transient',
        });
      });

      final result = await repository
          .resolveNearbyAreas(center: center, radiusKm: 5)
          .run();

      final discovery = result.getOrElse(
        (_) => const NearbyAreasResult(areas: []),
      );
      expect(discovery.areas, isNotEmpty);
      expect(discovery.hadPartialFailure, isTrue);
    });

    test('bounds the sample grid to maxSamples and coarsens spacing '
        'deterministically for a large radius', () async {
      stubAll({'status': 'ZERO_RESULTS', 'results': <dynamic>[]});
      final bounded = GoogleNearbyAreasRepositoryImpl(
        apiKey: 'key',
        dio: dio,
        gridSpacingKm: 1.5,
        maxSamples: 10,
        concurrency: 8,
      );

      await bounded.resolveNearbyAreas(center: center, radiusKm: 15).run();

      final calls = verify(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).callCount;
      expect(calls, lessThanOrEqualTo(10));
    });

    test('caches reverse-geocode results by quantized sample coordinate, '
        'avoiding duplicate calls across resolves for the same area', () async {
      var calls = 0;
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async {
        calls++;
        return buildResponse({
          'status': 'OK',
          'results': [
            uaeResult(
              placeId: 'ChIJ_cached',
              name: 'Cached Area',
              lat: center.latitude,
              lng: center.longitude,
            ),
          ],
        });
      });

      await repository.resolveNearbyAreas(center: center, radiusKm: 1).run();
      final firstCallCount = calls;
      expect(firstCallCount, greaterThan(0));

      await repository.resolveNearbyAreas(center: center, radiusKm: 1).run();

      // Second resolve over the identical grid hits the cache — no new calls.
      expect(calls, firstCallCount);
    });
  });
}
