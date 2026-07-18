import 'package:equatable/equatable.dart';
import 'package:maps/maps.dart';

/// Result returned from the Coverage Area screen.
class CoverageAreaResult extends Equatable {
  const CoverageAreaResult({
    required this.position,
    required this.address,
    required this.radiusKm,
    this.autoAreas = const [],
    this.extraAreas = const [],
  });

  final LatLng position;
  final String address;
  final double radiusKm;

  /// Auto-resolved areas from the radius overlay. Each carries a
  /// coordinate-based [ServingArea.placeId] and a human-readable
  /// [ServingArea.name]; the name is what users see, never the place ID.
  final List<ServingArea> autoAreas;
  final List<ServingArea> extraAreas;

  List<ServingArea> get servingAreas => [...autoAreas, ...extraAreas];

  List<String> get servingAreaPlaceIds => [
    ...autoAreas.map((a) => a.placeId),
    ...extraAreas.map((a) => a.placeId),
  ];

  @override
  List<Object?> get props => [
    position,
    address,
    radiusKm,
    autoAreas,
    extraAreas,
  ];
}
