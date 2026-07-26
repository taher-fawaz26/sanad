import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Parameters for resolving a coverage location: the reverse-geocoded address
/// of [center] plus the list of nearby areas within [radiusKm].
///
/// This type is intentionally feature-agnostic — it carries only geographic
/// inputs. How the resolved areas are used (create, edit, recalculate) is a
/// concern of the consuming feature, not of the maps platform.
class CoverageLocationIntent extends Equatable {
  const CoverageLocationIntent({
    required this.center,
    required this.radiusKm,
    this.localeIdentifier,
  });

  final LatLng center;
  final double radiusKm;
  final String? localeIdentifier;

  @override
  List<Object?> get props => [center, radiusKm, localeIdentifier];
}
