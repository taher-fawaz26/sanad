import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// A geographic position with an optional resolved address.
class MapPosition extends Equatable {
  const MapPosition({
    required this.latLng,
    this.address,
    this.placeId,
  });

  final LatLng latLng;
  final String? address;
  final String? placeId;

  double get latitude => latLng.latitude;
  double get longitude => latLng.longitude;

  MapPosition copyWith({
    LatLng? latLng,
    String? address,
    String? placeId,
  }) {
    return MapPosition(
      latLng: latLng ?? this.latLng,
      address: address ?? this.address,
      placeId: placeId ?? this.placeId,
    );
  }

  @override
  List<Object?> get props => [latLng, address, placeId];
}
