import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/area_entity.dart';
import 'package:maps/src/domain/entities/serving_area.dart';
import 'package:maps/src/domain/repositories/locations_repository.dart';
import 'package:maps/src/domain/usecases/coverage_location_intent.dart';
import 'package:maps/src/presentation/utils/geo_math.dart';

class ResolveNearbyAreasUseCase
    implements UseCase<List<ServingArea>, ResolveNearbyAreasParams> {
  const ResolveNearbyAreasUseCase(this._locationsRepository);

  final LocationsRepository _locationsRepository;

  @override
  TaskEither<Failure, List<ServingArea>> call(
    ResolveNearbyAreasParams params,
  ) => _locationsRepository
      .getAreasByCity(cityId: params.cityId)
      .map(
        (areas) => _filterAndMap(
          areas: areas,
          center: params.intent.center,
          radiusKm: params.intent.radiusKm,
          useArabic: params.intent.localeIdentifier?.startsWith('ar') ?? false,
        ),
      );

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
