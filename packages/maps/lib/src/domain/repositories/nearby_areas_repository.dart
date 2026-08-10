import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/serving_area.dart';

/// Result of a [NearbyAreasRepository.resolveNearbyAreas] call.
///
/// [hadPartialFailure] is true when at least one sample request failed but
/// others succeeded — [areas] still reflects the successful samples, but the
/// caller should surface that coverage may be incomplete rather than
/// presenting the result as a fully successful discovery.
class NearbyAreasResult extends Equatable {
  const NearbyAreasResult({
    required this.areas,
    this.hadPartialFailure = false,
  });

  final List<ServingArea> areas;
  final bool hadPartialFailure;

  @override
  List<Object?> get props => [areas, hadPartialFailure];
}

/// Resolves the serving areas (neighborhoods) that fall within a coverage
/// radius, each carrying its real Google `place_id`.
///
/// Unlike the previous backend-catalogue source, areas are derived entirely
/// from the Google Maps stack so the `place_id`s submitted when creating a
/// branch match what Google returns.
abstract interface class NearbyAreasRepository {
  TaskEither<Failure, NearbyAreasResult> resolveNearbyAreas({
    required LatLng center,
    required double radiusKm,
    String? languageCode,
  });
}
