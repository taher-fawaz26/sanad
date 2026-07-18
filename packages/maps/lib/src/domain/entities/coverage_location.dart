import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/serving_area.dart';

class CoverageLocation extends Equatable {
  const CoverageLocation({
    required this.center,
    required this.address,
    required this.nearbyAreas,
  });

  final LatLng center;
  final String address;
  final List<ServingArea> nearbyAreas;

  @override
  List<Object?> get props => [center, address, nearbyAreas];
}
