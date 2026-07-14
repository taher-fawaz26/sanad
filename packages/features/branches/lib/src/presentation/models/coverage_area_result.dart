import 'package:equatable/equatable.dart';
import 'package:maps/maps.dart';

/// Result returned from the Coverage Area screen.
class CoverageAreaResult extends Equatable {
  const CoverageAreaResult({
    required this.position,
    required this.address,
    required this.radiusKm,
    this.autoAreaNames = const [],
    this.extraArea,
  });

  final LatLng position;
  final String address;
  final double radiusKm;
  final List<String> autoAreaNames;
  final ServingArea? extraArea;

  List<ServingArea> get servingAreas => [
        ...autoAreaNames.map(
          (name) => ServingArea(
            placeId: name,
            name: name,
            address: '',
            latLng: position,
          ),
        ),
        if (extraArea != null) extraArea!,
      ];

  List<String> get servingAreaPlaceIds => [
        ...autoAreaNames,
        if (extraArea != null) extraArea!.placeId,
      ];

  @override
  List<Object?> get props => [
        position,
        address,
        radiusKm,
        autoAreaNames,
        extraArea,
      ];
}
