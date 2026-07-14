import 'package:equatable/equatable.dart';
import 'package:maps/maps.dart';

/// Result returned from the Coverage Area screen.
class CoverageAreaResult extends Equatable {
  const CoverageAreaResult({
    required this.position,
    required this.address,
    required this.radiusKm,
    this.servingAreas = const [],
  });

  final LatLng position;
  final String address;
  final double radiusKm;
  final List<ServingArea> servingAreas;

  @override
  List<Object?> get props => [position, address, radiusKm, servingAreas];
}
