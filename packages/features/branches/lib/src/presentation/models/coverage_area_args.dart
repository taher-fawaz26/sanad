import 'package:equatable/equatable.dart';
import 'package:maps/maps.dart';

/// Optional seed data when opening the coverage area screen.
class CoverageAreaArgs extends Equatable {
  const CoverageAreaArgs({
    this.position,
    this.address,
    this.radiusKm,
    this.servingAreas = const [],
  });

  final LatLng? position;
  final String? address;
  final double? radiusKm;
  final List<ServingArea> servingAreas;

  @override
  List<Object?> get props => [position, address, radiusKm, servingAreas];
}
