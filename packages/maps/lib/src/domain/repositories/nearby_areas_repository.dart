import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/serving_area.dart';

/// Resolves the serving areas (neighborhoods) that fall within a coverage
/// radius, each carrying its real Google `place_id`.
///
/// Unlike the previous backend-catalogue source, areas are derived entirely
/// from the Google Maps stack so the `place_id`s submitted when creating a
/// branch match what Google returns.
abstract interface class NearbyAreasRepository {
  TaskEither<Failure, List<ServingArea>> resolveNearbyAreas({
    required LatLng center,
    required double radiusKm,
    String? languageCode,
  });
}
