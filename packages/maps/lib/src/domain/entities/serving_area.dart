import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ServingArea extends Equatable {
  const ServingArea({
    required this.placeId,
    required this.name,
    required this.address,
    required this.latLng,
  });

  final String placeId;
  final String name;
  final String address;
  final LatLng latLng;

  @override
  List<Object?> get props => [placeId, name, address, latLng];
}
