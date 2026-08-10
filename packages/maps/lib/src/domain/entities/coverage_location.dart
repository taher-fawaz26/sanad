import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/serving_area.dart';

class CoverageLocation extends Equatable {
  const CoverageLocation({
    required this.center,
    required this.address,
    required this.nearbyAreas,
    this.isoCountryCode,
    this.hadPartialFailure = false,
  });

  final LatLng center;
  final String address;
  final List<ServingArea> nearbyAreas;

  /// ISO 3166-1 alpha-2 country of [center] (uppercased), when known. Used to
  /// keep the coverage centre inside the supported country.
  final String? isoCountryCode;

  /// True when area discovery succeeded partially — some grid samples
  /// failed but others returned areas. Coverage may be incomplete.
  final bool hadPartialFailure;

  @override
  List<Object?> get props => [
    center,
    address,
    nearbyAreas,
    isoCountryCode,
    hadPartialFailure,
  ];
}
