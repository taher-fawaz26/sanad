import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/area_entity.dart';
import 'package:maps/src/domain/repositories/locations_repository.dart';
import 'package:maps/src/domain/usecases/coverage_location_intent.dart';
import 'package:maps/src/domain/usecases/resolve_nearby_areas_usecase.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocationsRepository extends Mock implements LocationsRepository {}

void main() {
  late _MockLocationsRepository repository;
  late ResolveNearbyAreasUseCase useCase;

  setUp(() {
    repository = _MockLocationsRepository();
    useCase = ResolveNearbyAreasUseCase(repository);
  });

  AreaEntity _area({
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

  group('ResolveNearbyAreasUseCase', () {
    test('filters areas within radius', () async {
      final center = const LatLng(25.2048, 55.2708);

      when(() => repository.getAreasByCity(cityId: 'city-1')).thenReturn(
        TaskEither.right([
          _area(id: 'near', placeId: 'ChIJ_near', lat: 25.205, lng: 55.271),
          _area(id: 'far', placeId: 'ChIJ_far', lat: 26.0, lng: 56.0),
        ]),
      );

      final result = await useCase(
        ResolveNearbyAreasParams(
          intent: CoverageLocationIntent(
            center: center,
            radiusKm: 5.0,
            cityId: 'city-1',
          ),
          cityId: 'city-1',
        ),
      ).run();

      expect(result.isRight(), isTrue);
      final areas = result.getOrElse((_) => []);
      expect(areas.length, 1);
      expect(areas[0].placeId, 'ChIJ_near');
    });

    test('returns empty list when no areas within radius', () async {
      when(() => repository.getAreasByCity(cityId: 'city-1')).thenReturn(
        TaskEither.right([
          _area(id: 'far1', placeId: 'ChIJ_far1', lat: 26.0, lng: 56.0),
          _area(id: 'far2', placeId: 'ChIJ_far2', lat: 27.0, lng: 57.0),
        ]),
      );

      final result = await useCase(
        ResolveNearbyAreasParams(
          intent: CoverageLocationIntent(
            center: const LatLng(25.2048, 55.2708),
            radiusKm: 1.0,
            cityId: 'city-1',
          ),
          cityId: 'city-1',
        ),
      ).run();

      final areas = result.getOrElse((_) => []);
      expect(areas, isEmpty);
    });

    test('uses Arabic names when locale is ar', () async {
      when(() => repository.getAreasByCity(cityId: 'city-1')).thenReturn(
        TaskEither.right([
          _area(id: 'a1', placeId: 'ChIJ_1', lat: 25.205, lng: 55.271),
        ]),
      );

      final result = await useCase(
        ResolveNearbyAreasParams(
          intent: CoverageLocationIntent(
            center: const LatLng(25.2048, 55.2708),
            radiusKm: 5.0,
            localeIdentifier: 'ar_AE',
            cityId: 'city-1',
          ),
          cityId: 'city-1',
        ),
      ).run();

      final areas = result.getOrElse((_) => []);
      expect(areas[0].name, 'منطقة a1');
    });

    test('uses English names when locale is en', () async {
      when(() => repository.getAreasByCity(cityId: 'city-1')).thenReturn(
        TaskEither.right([
          _area(id: 'a1', placeId: 'ChIJ_1', lat: 25.205, lng: 55.271),
        ]),
      );

      final result = await useCase(
        ResolveNearbyAreasParams(
          intent: CoverageLocationIntent(
            center: const LatLng(25.2048, 55.2708),
            radiusKm: 5.0,
            localeIdentifier: 'en_US',
            cityId: 'city-1',
          ),
          cityId: 'city-1',
        ),
      ).run();

      final areas = result.getOrElse((_) => []);
      expect(areas[0].name, 'Area a1');
    });

    test('all returned placeIds are real backend IDs, not synthetic', () async {
      when(() => repository.getAreasByCity(cityId: 'city-1')).thenReturn(
        TaskEither.right([
          _area(
            id: 'a1',
            placeId: 'ChIJ3QPOgqjK9T4R3KMk0f9ucsg',
            lat: 25.205,
            lng: 55.271,
          ),
          _area(
            id: 'a2',
            placeId: 'ChIJRULP3yjK9T4RqYPvJA6bEHo',
            lat: 25.204,
            lng: 55.270,
          ),
        ]),
      );

      final result = await useCase(
        ResolveNearbyAreasParams(
          intent: CoverageLocationIntent(
            center: const LatLng(25.2048, 55.2708),
            radiusKm: 10.0,
            cityId: 'city-1',
          ),
          cityId: 'city-1',
        ),
      ).run();

      final areas = result.getOrElse((_) => []);
      for (final area in areas) {
        expect(area.placeId.startsWith('latlng:'), isFalse);
        expect(area.placeId.isNotEmpty, isTrue);
      }
    });

    test('propagates repository failure', () async {
      when(() => repository.getAreasByCity(cityId: 'city-1')).thenReturn(
        TaskEither.left(const UnknownFailure(message: 'test error')),
      );

      final result = await useCase(
        ResolveNearbyAreasParams(
          intent: CoverageLocationIntent(
            center: const LatLng(25.2048, 55.2708),
            radiusKm: 5.0,
            cityId: 'city-1',
          ),
          cityId: 'city-1',
        ),
      ).run();

      expect(result.isLeft(), isTrue);
    });
  });
}
