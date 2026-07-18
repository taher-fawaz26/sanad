import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:maps/src/domain/entities/coverage_location.dart';
import 'package:maps/src/domain/usecases/coverage_location_intent.dart';
import 'package:maps/src/domain/usecases/resolve_nearby_areas_usecase.dart';
import 'package:maps/src/domain/usecases/reverse_geocode_usecase.dart';

class ResolveCoverageLocationUseCase
    implements UseCase<CoverageLocation, CoverageLocationIntent> {
  const ResolveCoverageLocationUseCase(
    this._reverseGeocode,
    this._resolveNearbyAreas,
  );

  final ReverseGeocodeUseCase _reverseGeocode;
  final ResolveNearbyAreasUseCase _resolveNearbyAreas;

  @override
  TaskEither<Failure, CoverageLocation> call(
    CoverageLocationIntent intent,
  ) {
    final geocodeTask = _reverseGeocode(
      ReverseGeocodeParams(
        position: intent.center,
        localeIdentifier: intent.localeIdentifier,
      ),
    );

    if (intent.cityId == null) {
      return geocodeTask.map(
        (geocoded) => CoverageLocation(
          center: intent.center,
          address: geocoded.formattedAddress,
          nearbyAreas: const [],
        ),
      );
    }

    return geocodeTask.flatMap(
      (geocoded) =>
          _resolveNearbyAreas(
            ResolveNearbyAreasParams(intent: intent, cityId: intent.cityId!),
          ).map(
            (nearbyAreas) => CoverageLocation(
              center: intent.center,
              address: geocoded.formattedAddress,
              nearbyAreas: nearbyAreas,
            ),
          ),
    );
  }
}
