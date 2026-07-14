import 'package:equatable/equatable.dart';
import 'package:maps/maps.dart';

/// Result returned from the Coverage Area screen.
class CoverageAreaResult extends Equatable {
  const CoverageAreaResult({
    required this.position,
    required this.address,
    required this.radiusKm,
    this.autoAreaNames = const [],
    this.extraAreas = const [],
  });

  final LatLng position;
  final String address;
  final double radiusKm;
  final List<String> autoAreaNames;
  final List<ServingArea> extraAreas;

  List<ServingArea> get servingAreas => [
        ...autoAreaNames.map(
          (name) => ServingArea(
            placeId: name,
            name: name,
            address: '',
            latLng: position,
          ),
        ),
        ...extraAreas,
      ];

  List<String> get servingAreaPlaceIds => [
        ...autoAreaNames,
        ...extraAreas.map((area) => area.placeId),
      ];

  @override
  List<Object?> get props => [
        position,
        address,
        radiusKm,
        autoAreaNames,
        extraAreas,
      ];
}
