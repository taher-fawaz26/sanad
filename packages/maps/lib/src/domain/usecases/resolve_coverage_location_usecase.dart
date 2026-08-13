import 'package:app_logger/app_logger.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:maps/src/domain/entities/coverage_location.dart';
import 'package:maps/src/domain/entities/geocoded_address.dart';
import 'package:maps/src/domain/repositories/nearby_areas_repository.dart';
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
    return TaskEither<Failure, CoverageLocation>(() async {
      appLogger.d(
        '[ResolveCoverageLocation] center=(${intent.center.latitude}, '
        '${intent.center.longitude}) radiusKm=${intent.radiusKm}',
      );

      // Run independently — NOT chained. The reverse-geocode below only
      // produces a display address label (via the native platform geocoder);
      // the nearby-areas resolution produces the actual Google-discovered
      // serving areas (via REST reverse geocoding of a sample grid). The
      // native geocoder is a known emulator-vs-physical-device divergence
      // (it can throw/return empty on some devices while working fine on an
      // emulator) — it must never zero out area discovery, which previously
      // happened because a `flatMap` chain made area discovery depend on
      // this address lookup succeeding first.
      final results = await Future.wait([
        _reverseGeocode(
          ReverseGeocodeParams(
            position: intent.center,
            localeIdentifier: intent.localeIdentifier,
          ),
        ).run(),
        _resolveNearbyAreas(
          ResolveNearbyAreasParams(intent: intent),
        ).run(),
      ]);

      final geocodeResult = results[0] as Either<Failure, GeocodedAddress>;
      final nearbyAreasResult =
          results[1] as Either<Failure, NearbyAreasResult>;

      geocodeResult.match(
        (failure) => appLogger.w(
          '[ResolveCoverageLocation] reverse-geocode (address label) failed '
          '— continuing with area discovery regardless: '
          '${failure.runtimeType}',
        ),
        (geocoded) => appLogger.d(
          '[ResolveCoverageLocation] reverse-geocode ok, '
          'areaName=${geocoded.areaName}',
        ),
      );

      // Serving areas are the whole point of this screen — only that
      // failure is fatal to the overall result.
      return nearbyAreasResult.match(
        (failure) {
          appLogger.w(
            '[ResolveCoverageLocation] nearby-areas discovery failed: '
            '${failure.runtimeType}',
          );
          return Left<Failure, CoverageLocation>(failure);
        },
        (nearbyAreas) {
          appLogger.d(
            '[ResolveCoverageLocation] discovered ${nearbyAreas.areas.length} '
            'area(s), hadPartialFailure=${nearbyAreas.hadPartialFailure}',
          );
          // The address label is best-effort: fall back to an empty label
          // rather than losing the discovered areas over it.
          final geocoded = geocodeResult.getOrElse(
            (_) => const GeocodedAddress(formattedAddress: ''),
          );
          return Right<Failure, CoverageLocation>(
            CoverageLocation(
              center: intent.center,
              address: geocoded.formattedAddress,
              nearbyAreas: nearbyAreas.areas,
              isoCountryCode: geocoded.isoCountryCode,
              hadPartialFailure: nearbyAreas.hadPartialFailure,
            ),
          );
        },
      );
    });
  }
}
