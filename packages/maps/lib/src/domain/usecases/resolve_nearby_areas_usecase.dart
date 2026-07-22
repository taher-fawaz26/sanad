import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/area_entity.dart';
import 'package:maps/src/domain/entities/serving_area.dart';
import 'package:maps/src/domain/repositories/geocoding_repository.dart';
import 'package:maps/src/domain/repositories/locations_repository.dart';
import 'package:maps/src/domain/usecases/coverage_location_intent.dart';
import 'package:maps/src/presentation/utils/geo_math.dart';

/// Resolves the serving areas covered by a coverage circle.
///
/// Primary source is the backend city-area catalogue ([LocationsRepository]),
/// radius-filtered around the pin — this yields the official, stable area
/// identities the backend expects on save.
///
/// Fallback source is the on-device geocoder ([GeocodingRepository]): when the
/// selected city has no catalogue areas within the radius (sparse or
/// mis-located backend data — e.g. a city record with a single far-away area),
/// the primary filter would return an empty set and the UI would show
/// "0 areas" for a perfectly valid location. In that case we derive nearby
/// area names from the geocoder around the pin, which works anywhere and is
/// save-compatible (both sources produce `placeId` + `name`). This restores the
/// pre-refactor behaviour without giving up official areas where they exist.
class ResolveNearbyAreasUseCase
    implements UseCase<List<ServingArea>, ResolveNearbyAreasParams> {
  const ResolveNearbyAreasUseCase(
    this._locationsRepository,
    this._geocodingRepository,
  );

  final LocationsRepository _locationsRepository;
  final GeocodingRepository _geocodingRepository;

  @override
  TaskEither<Failure, List<ServingArea>> call(
    ResolveNearbyAreasParams params,
  ) {
    final intent = params.intent;
    final useArabic = intent.localeIdentifier?.startsWith('ar') ?? false;

    return TaskEither(() async {
      // Primary: official city catalogue, radius-filtered around the pin.
      final catalogue = await _locationsRepository
          .getAreasByCity(cityId: params.cityId)
          .run();

      final matched = catalogue.match(
        (_) => const <ServingArea>[],
        (areas) => _filterAndMap(
          areas: areas,
          center: intent.center,
          radiusKm: intent.radiusKm,
          useArabic: useArabic,
        ),
      );
      if (matched.isNotEmpty) return Either.right(matched);

      // Fallback: geocoder-derived nearby areas (works even when the city
      // catalogue is empty, mis-located, or the fetch failed).
      return _geocodingRepository
          .nearbyAreaNames(
            center: intent.center,
            radiusKm: intent.radiusKm,
            localeIdentifier: intent.localeIdentifier,
          )
          .run();
    });
  }

  static List<ServingArea> _filterAndMap({
    required List<AreaEntity> areas,
    required LatLng center,
    required double radiusKm,
    required bool useArabic,
  }) {
    final result = <ServingArea>[];
    for (final area in areas) {
      final areaPos = LatLng(area.latitude, area.longitude);
      final distance = GeoMath.distanceKm(center, areaPos);
      if (distance <= radiusKm) {
        result.add(
          ServingArea(
            placeId: area.placeId,
            name: useArabic ? area.nameAr : area.nameEn,
            address: '',
            latLng: areaPos,
          ),
        );
      }
    }
    return result;
  }
}

class ResolveNearbyAreasParams {
  const ResolveNearbyAreasParams({
    required this.intent,
    required this.cityId,
  });

  final CoverageLocationIntent intent;
  final String cityId;
}
