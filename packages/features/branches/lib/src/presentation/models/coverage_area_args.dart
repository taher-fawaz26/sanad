import 'package:equatable/equatable.dart';
import 'package:maps/maps.dart';

/// Optional seed data when opening the coverage area screen.
class CoverageAreaArgs extends Equatable {
  const CoverageAreaArgs({
    this.position,
    this.address,
    this.radiusKm,
  });

  final LatLng? position;
  final String? address;
  final double? radiusKm;

  @override
  List<Object?> get props => [position, address, radiusKm];
}
