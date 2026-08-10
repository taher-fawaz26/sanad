import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/serving_area.dart';
import 'package:maps/src/domain/repositories/nearby_areas_repository.dart';
import 'package:maps/src/domain/usecases/coverage_location_intent.dart';
import 'package:maps/src/domain/usecases/resolve_nearby_areas_usecase.dart';
import 'package:mocktail/mocktail.dart';

class _MockNearbyAreasRepository extends Mock
    implements NearbyAreasRepository {}

void main() {
  late _MockNearbyAreasRepository repository;
  late ResolveNearbyAreasUseCase useCase;

  const center = LatLng(25.2048, 55.2708);

  setUpAll(() {
    registerFallbackValue(const LatLng(0, 0));
  });

  setUp(() {
    repository = _MockNearbyAreasRepository();
    useCase = ResolveNearbyAreasUseCase(repository);
  });

  group('ResolveNearbyAreasUseCase', () {
    test('forwards the intent geometry + locale to the repository', () async {
      when(
        () => repository.resolveNearbyAreas(
          center: center,
          radiusKm: 5,
          languageCode: 'ar_AE',
        ),
      ).thenReturn(
        TaskEither.right(
          const NearbyAreasResult(
            areas: [
              ServingArea(
                placeId: 'ChIJ_near',
                name: 'منطقة',
                address: '',
                latLng: center,
              ),
            ],
          ),
        ),
      );

      final result = await useCase(
        const ResolveNearbyAreasParams(
          intent: CoverageLocationIntent(
            center: center,
            radiusKm: 5,
            localeIdentifier: 'ar_AE',
          ),
        ),
      ).run();

      expect(
        result
            .getOrElse((_) => const NearbyAreasResult(areas: []))
            .areas
            .single
            .placeId,
        'ChIJ_near',
      );
      verify(
        () => repository.resolveNearbyAreas(
          center: center,
          radiusKm: 5,
          languageCode: 'ar_AE',
        ),
      ).called(1);
    });

    test('propagates repository failure', () async {
      when(
        () => repository.resolveNearbyAreas(
          center: any(named: 'center'),
          radiusKm: any(named: 'radiusKm'),
          languageCode: any(named: 'languageCode'),
        ),
      ).thenReturn(
        TaskEither.left(const UnknownFailure(message: 'test error')),
      );

      final result = await useCase(
        const ResolveNearbyAreasParams(
          intent: CoverageLocationIntent(center: center, radiusKm: 5),
        ),
      ).run();

      expect(result.isLeft(), isTrue);
    });
  });
}
