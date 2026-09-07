import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/data/repositories/google_reverse_geocode_place_repository_impl.dart';
import 'package:maps/src/domain/failures/places_failure.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late GoogleReverseGeocodePlaceRepositoryImpl repository;

  const position = LatLng(25.2048, 55.2708);

  Response<Map<String, dynamic>> buildResponse(Map<String, dynamic> body) =>
      Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: 'geocode'),
        statusCode: 200,
        data: body,
      );

  Map<String, dynamic> result({
    required String placeId,
    String formatted = 'Dubai Marina Mall, Dubai',
    String country = 'AE',
  }) => {
    'place_id': placeId,
    'formatted_address': formatted,
    'address_components': [
      {
        'long_name': 'United Arab Emirates',
        'short_name': country,
        'types': ['country', 'political'],
      },
    ],
  };

  void stub(Map<String, dynamic> body) {
    when(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer((_) async => buildResponse(body));
  }

  setUp(() {
    dio = _MockDio();
    repository = GoogleReverseGeocodePlaceRepositoryImpl(
      apiKey: 'test-key',
      dio: dio,
    );
  });

  group('GoogleReverseGeocodePlaceRepositoryImpl', () {
    test(
      'maps the first usable result to a GeocodedAddress with place_id',
      () async {
        stub({
          'status': 'OK',
          'results': [
            result(
              placeId: 'ChIJ_marina_mall',
              formatted: 'Marina Mall, Dubai',
            ),
          ],
        });

        final either = await repository
            .reverseGeocodePlace(
              position: position,
            )
            .run();

        final address = either.getRight().toNullable();
        expect(address, isNotNull);
        expect(address!.placeId, 'ChIJ_marina_mall');
        expect(address.formattedAddress, 'Marina Mall, Dubai');
        expect(address.isoCountryCode, 'AE');
      },
    );

    test('skips a result lacking a place_id and takes the next', () async {
      stub({
        'status': 'OK',
        'results': [
          {'formatted_address': 'No id here'},
          result(placeId: 'ChIJ_second'),
        ],
      });

      final address =
          (await repository
                  .reverseGeocodePlace(
                    position: position,
                  )
                  .run())
              .getRight()
              .toNullable();

      expect(address?.placeId, 'ChIJ_second');
    });

    test('returns null (not a failure) on ZERO_RESULTS', () async {
      stub({'status': 'ZERO_RESULTS', 'results': <dynamic>[]});

      final either = await repository
          .reverseGeocodePlace(
            position: position,
          )
          .run();

      expect(either.isRight(), isTrue);
      expect(either.getRight().toNullable(), isNull);
    });

    test('maps REQUEST_DENIED to a PlacesApiKeyFailure', () async {
      stub({
        'status': 'REQUEST_DENIED',
        'error_message': 'bad key',
        'results': <dynamic>[],
      });

      final either = await repository
          .reverseGeocodePlace(
            position: position,
          )
          .run();

      expect(either.isLeft(), isTrue);
      expect(either.getLeft().toNullable(), isA<PlacesApiKeyFailure>());
    });

    test('maps a Dio timeout to a PlacesTimeoutFailure', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: 'geocode'),
          type: DioExceptionType.receiveTimeout,
        ),
      );

      final either = await repository
          .reverseGeocodePlace(
            position: position,
          )
          .run();

      expect(either.getLeft().toNullable(), isA<PlacesTimeoutFailure>());
    });
  });
}
