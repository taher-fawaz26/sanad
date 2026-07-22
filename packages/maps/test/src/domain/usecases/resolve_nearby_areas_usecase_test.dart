import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/area_entity.dart';
import 'package:maps/src/domain/entities/serving_area.dart';
import 'package:maps/src/domain/repositories/geocoding_repository.dart';
import 'package:maps/src/domain/repositories/locations_repository.dart';
import 'package:maps/src/domain/usecases/coverage_location_intent.dart';
import 'package:maps/src/domain/usecases/resolve_nearby_areas_usecase.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocationsRepository extends Mock implements LocationsRepository {}

class _MockGeocodingRepository extends Mock implements GeocodingRepository {}

void main() {
  late _MockLocationsRepository repository;
  late _MockGeocodingRepository geocoder;
  late ResolveNearbyAreasUseCase useCase;

  const center = LatLng(25.2048, 55.2708);

  setUpAll(() => registerFallbackValue(const LatLng(0, 0)));

  setUp(() {
    repository = _MockLocationsRepository();
    geocoder = _MockGeocodingRepository();
    useCase = ResolveNearbyAreasUseCase(repository, geocoder);
  });

  AreaEntity area({
    required String id,
    required String placeId,
    required double lat,
    required double lng,
  }) => AreaEntity(
    id: id,
    placeId: placeId,
    nameEn: 'Area $id',
    nameAr: 'منطقة $id',
    latitude: lat,
    longitude: lng,
    cityId: 'city-1',
    countryId: 'country-1',
  );

  ResolveNearbyAreasParams params({
    double radiusKm = 5.0,
    String? locale,
  }) => ResolveNearbyAreasParams(
    intent: CoverageLocationIntent(
      center: center,
      radiusKm: radiusKm,
      localeIdentifier: locale,
      cityId: 'city-1',
    ),
    cityId: 'city-1',
  );

  group('ResolveNearbyAreasUseCase — catalogue primary', () {
    test(
      'filters catalogue areas within radius (geocoder untouched)',
      () async {
        when(() => repository.getAreasByCity(cityId: 'city-1')).thenReturn(
          TaskEither.right([
            area(id: 'near', placeId: 'ChIJ_near', lat: 25.205, lng: 55.271),
            area(id: 'far', placeId: 'ChIJ_far', lat: 26.0, lng: 56.0),
          ]),
        );

        final result = await useCase(params()).run();

        final areas = result.getOrElse((_) => []);
        expect(areas.length, 1);
        expect(areas[0].placeId, 'ChIJ_near');
        verifyNever(
          () => geocoder.nearbyAreaNames(
            center: any(named: 'center'),
            radiusKm: any(named: 'radiusKm'),
            localeIdentifier: any(named: 'localeIdentifier'),
          ),
        );
      },
    );

    test('uses Arabic names when locale is ar', () async {
      when(() => repository.getAreasByCity(cityId: 'city-1')).thenReturn(
        TaskEither.right([
          area(id: 'a1', placeId: 'ChIJ_1', lat: 25.205, lng: 55.271),
        ]),
      );

      final result = await useCase(params(locale: 'ar_AE')).run();

      expect(result.getOrElse((_) => [])[0].name, 'منطقة a1');
    });

    test('uses English names when locale is en', () async {
      when(() => repository.getAreasByCity(cityId: 'city-1')).thenReturn(
        TaskEither.right([
          area(id: 'a1', placeId: 'ChIJ_1', lat: 25.205, lng: 55.271),
        ]),
      );

      final result = await useCase(params(locale: 'en_US')).run();

      expect(result.getOrElse((_) => [])[0].name, 'Area a1');
    });
  });

  group('ResolveNearbyAreasUseCase — geocoder fallback', () {
    final geocoded = [
      const ServingArea(
        placeId: 'ChIJ_geocoded',
        name: 'Nearby Neighbourhood',
        address: '',
        latLng: center,
      ),
    ];

    test(
      'falls back to geocoder when no catalogue area is in radius',
      () async {
        // Catalogue returns only a far-away area (mimics the Dubai city record
        // whose single area is ~113 km from the pin) → 0 matched → fallback.
        when(() => repository.getAreasByCity(cityId: 'city-1')).thenReturn(
          TaskEither.right([
            area(id: 'far', placeId: 'ChIJ_far', lat: 26.5, lng: 56.5),
          ]),
        );
        when(
          () => geocoder.nearbyAreaNames(
            center: center,
            radiusKm: 5.0,
            localeIdentifier: null,
          ),
        ).thenReturn(TaskEither.right(geocoded));

        final result = await useCase(params()).run();

        final areas = result.getOrElse((_) => []);
        expect(areas.length, 1);
        expect(areas[0].placeId, 'ChIJ_geocoded');
      },
    );

    test('falls back to geocoder when catalogue fetch fails', () async {
      when(() => repository.getAreasByCity(cityId: 'city-1')).thenReturn(
        TaskEither.left(const UnknownFailure(message: 'network')),
      );
      when(
        () => geocoder.nearbyAreaNames(
          center: center,
          radiusKm: 5.0,
          localeIdentifier: null,
        ),
      ).thenReturn(TaskEither.right(geocoded));

      final result = await useCase(params()).run();

      expect(result.getOrElse((_) => [])[0].placeId, 'ChIJ_geocoded');
    });

    test('returns failure when both catalogue and geocoder fail', () async {
      when(() => repository.getAreasByCity(cityId: 'city-1')).thenReturn(
        TaskEither.left(const UnknownFailure(message: 'network')),
      );
      when(
        () => geocoder.nearbyAreaNames(
          center: center,
          radiusKm: 5.0,
          localeIdentifier: null,
        ),
      ).thenReturn(TaskEither.left(const UnknownFailure(message: 'geocode')));

      final result = await useCase(params()).run();

      expect(result.isLeft(), isTrue);
    });
  });
}
