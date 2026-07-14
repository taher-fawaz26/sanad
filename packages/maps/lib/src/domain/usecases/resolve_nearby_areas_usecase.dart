import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:maps/src/domain/repositories/branch_serving_areas_repository.dart';
import 'package:maps/src/domain/repositories/geocoding_repository.dart';
import 'package:maps/src/domain/usecases/coverage_location_intent.dart';

class ResolveNearbyAreasUseCase
    implements UseCase<List<String>, CoverageLocationIntent> {
  const ResolveNearbyAreasUseCase(
    this._geocodingRepository,
    this._branchServingAreasRepository,
  );

  final GeocodingRepository _geocodingRepository;
  final BranchServingAreasRepository _branchServingAreasRepository;

  @override
  TaskEither<Failure, List<String>> call(CoverageLocationIntent intent) =>
      switch (intent) {
        CreateCoverageIntent() => _geocodingRepository.nearbyAreaNames(
            center: intent.center,
            radiusKm: intent.radiusKm,
            localeIdentifier: intent.localeIdentifier,
          ),
        EditCoverageIntent(:final branchId) =>
          _branchServingAreasRepository.getServingAreas(branchId).map(
            (areas) => areas.map((area) => area.name).toList(growable: false),
          ),
        RecalculateCoverageIntent() => _geocodingRepository.nearbyAreaNames(
            center: intent.center,
            radiusKm: intent.radiusKm,
            localeIdentifier: intent.localeIdentifier,
          ),
      };
}
