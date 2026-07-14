import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:maps/src/domain/repositories/geocoding_repository.dart';
import 'package:maps/src/domain/usecases/coverage_location_intent.dart';

/// Resolves the nearby area names around a coverage center via the geocoding
/// provider. The maps platform never loads feature-specific saved areas; a
/// consuming feature seeds those directly into the coverage bloc when editing.
class ResolveNearbyAreasUseCase
    implements UseCase<List<String>, CoverageLocationIntent> {
  const ResolveNearbyAreasUseCase(this._geocodingRepository);

  final GeocodingRepository _geocodingRepository;

  @override
  TaskEither<Failure, List<String>> call(CoverageLocationIntent intent) =>
      _geocodingRepository.nearbyAreaNames(
        center: intent.center,
        radiusKm: intent.radiusKm,
        localeIdentifier: intent.localeIdentifier,
      );
}
