import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/geocoded_address.dart';
import 'package:maps/src/domain/entities/serving_area.dart';
import 'package:maps/src/domain/repositories/geocoding_repository.dart';
import 'package:maps/src/domain/repositories/nearby_areas_repository.dart';
import 'package:maps/src/domain/usecases/coverage_location_intent.dart';
import 'package:maps/src/domain/usecases/resolve_coverage_location_usecase.dart';
import 'package:maps/src/domain/usecases/resolve_nearby_areas_usecase.dart';
import 'package:maps/src/domain/usecases/reverse_geocode_usecase.dart';
import 'package:maps/src/services/location_failure_codes.dart';
import 'package:mocktail/mocktail.dart';

class _MockGeocodingRepository extends Mock implements GeocodingRepository {}

class _MockNearbyAreasRepository extends Mock
    implements NearbyAreasRepository {}

void main() {
  late _MockGeocodingRepository geocodingRepository;
  late _MockNearbyAreasRepository nearbyAreasRepository;
  late ResolveCoverageLocationUseCase useCase;

  const center = LatLng(25.2048, 55.2708);
  const intent = CoverageLocationIntent(center: center, radiusKm: 5);
  const area = ServingArea(
    placeId: 'ChIJ_near',
    name: 'Downtown',
    address: '',
    latLng: center,
  );

  setUpAll(() {
    registerFallbackValue(const LatLng(0, 0));
  });

  setUp(() {
    geocodingRepository = _MockGeocodingRepository();
    nearbyAreasRepository = _MockNearbyAreasRepository();
    useCase = ResolveCoverageLocationUseCase(
      ReverseGeocodeUseCase(geocodingRepository),
      ResolveNearbyAreasUseCase(nearbyAreasRepository),
    );

    when(
      () => nearbyAreasRepository.resolveNearbyAreas(
        center: any(named: 'center'),
        radiusKm: any(named: 'radiusKm'),
        languageCode: any(named: 'languageCode'),
      ),
    ).thenReturn(TaskEither.right(const NearbyAreasResult(areas: [area])));

    when(
      () => geocodingRepository.reverseGeocode(
        any(),
        localeIdentifier: any(named: 'localeIdentifier'),
      ),
    ).thenReturn(
      TaskEither.right(
        const GeocodedAddress(
          formattedAddress: '123 Main St',
          isoCountryCode: 'AE',
        ),
      ),
    );
  });

  group('ResolveCoverageLocationUseCase', () {
    test(
      'happy path: returns discovered areas and the geocoded address',
      () async {
        final result = await useCase(intent).run();

        final location = result.getOrElse((_) => throw StateError('left'));
        expect(location.nearbyAreas, [area]);
        expect(location.address, '123 Main St');
        expect(location.isoCountryCode, 'AE');
        expect(location.hadPartialFailure, isFalse);
      },
    );

    test(
      // Regression for the "serving areas work on emulator but not on a '
      // physical device" bug: the native reverse-geocode (address label
      // only) failing must not zero out area discovery — the two must
      // resolve independently.
      'reverse-geocode failure still returns the discovered areas '
      '(regression: device-only native geocoder failure must not zero out '
      'discovery)',
      () async {
        when(
          () => geocodingRepository.reverseGeocode(
            any(),
            localeIdentifier: any(named: 'localeIdentifier'),
          ),
        ).thenReturn(
          TaskEither.left(
            const LocationFailure(
              message: 'native geocoder unavailable',
              code: LocationFailureCodes.geocodingFailed,
            ),
          ),
        );

        final result = await useCase(intent).run();

        expect(result.isRight(), isTrue);
        final location = result.getOrElse((_) => throw StateError('left'));
        expect(location.nearbyAreas, [area]);
        // Address label degrades gracefully rather than blocking discovery.
        expect(location.address, isEmpty);
        expect(location.isoCountryCode, isNull);
      },
    );

    test(
      'nearby-areas failure is still fatal — areas are the point of this '
      'screen',
      () async {
        when(
          () => nearbyAreasRepository.resolveNearbyAreas(
            center: any(named: 'center'),
            radiusKm: any(named: 'radiusKm'),
            languageCode: any(named: 'languageCode'),
          ),
        ).thenReturn(
          TaskEither.left(const UnknownFailure(message: 'discovery failed')),
        );

        final result = await useCase(intent).run();

        expect(result.isLeft(), isTrue);
      },
    );

    test(
      'partial nearby-areas failure is surfaced via hadPartialFailure, not '
      'as an overall failure',
      () async {
        when(
          () => nearbyAreasRepository.resolveNearbyAreas(
            center: any(named: 'center'),
            radiusKm: any(named: 'radiusKm'),
            languageCode: any(named: 'languageCode'),
          ),
        ).thenReturn(
          TaskEither.right(
            const NearbyAreasResult(areas: [area], hadPartialFailure: true),
          ),
        );

        final result = await useCase(intent).run();

        final location = result.getOrElse((_) => throw StateError('left'));
        expect(location.hadPartialFailure, isTrue);
        expect(location.nearbyAreas, [area]);
      },
    );

    test('both operations failing is an overall failure', () async {
      when(
        () => geocodingRepository.reverseGeocode(
          any(),
          localeIdentifier: any(named: 'localeIdentifier'),
        ),
      ).thenReturn(
        TaskEither.left(
          const LocationFailure(
            message: 'native geocoder unavailable',
            code: LocationFailureCodes.geocodingFailed,
          ),
        ),
      );
      when(
        () => nearbyAreasRepository.resolveNearbyAreas(
          center: any(named: 'center'),
          radiusKm: any(named: 'radiusKm'),
          languageCode: any(named: 'languageCode'),
        ),
      ).thenReturn(
        TaskEither.left(const UnknownFailure(message: 'discovery failed')),
      );

      final result = await useCase(intent).run();

      expect(result.isLeft(), isTrue);
    });
  });
}
