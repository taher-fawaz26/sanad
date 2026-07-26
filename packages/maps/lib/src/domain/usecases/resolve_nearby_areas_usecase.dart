import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:maps/src/domain/entities/serving_area.dart';
import 'package:maps/src/domain/repositories/nearby_areas_repository.dart';
import 'package:maps/src/domain/usecases/coverage_location_intent.dart';

/// Resolves the serving areas within the coverage radius from Google (via
/// [NearbyAreasRepository]). Areas carry real Google `place_id`s.
class ResolveNearbyAreasUseCase
    implements UseCase<List<ServingArea>, ResolveNearbyAreasParams> {
  const ResolveNearbyAreasUseCase(this._nearbyAreasRepository);

  final NearbyAreasRepository _nearbyAreasRepository;

  @override
  TaskEither<Failure, List<ServingArea>> call(
    ResolveNearbyAreasParams params,
  ) => _nearbyAreasRepository.resolveNearbyAreas(
    center: params.intent.center,
    radiusKm: params.intent.radiusKm,
    languageCode: params.intent.localeIdentifier,
  );
}

class ResolveNearbyAreasParams {
  const ResolveNearbyAreasParams({required this.intent});

  final CoverageLocationIntent intent;
}
