import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPickerResult extends Equatable {
  const LocationPickerResult({
    required this.position,
    required this.address,
  });

  final LatLng position;
  final String address;

  @override
  List<Object?> get props => [position, address];
}
