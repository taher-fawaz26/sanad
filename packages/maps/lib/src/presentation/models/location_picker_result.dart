import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPickerResult extends Equatable {
  const LocationPickerResult({
    required this.position,
    required this.address,
    this.placeId,
  });

  final LatLng position;
  final String address;

  /// Google Places Autocomplete place ID, when the location was selected from
  /// a prediction. `null` when the position came from a map drag, GPS, or
  /// forward geocode.
  final String? placeId;

  @override
  List<Object?> get props => [position, address, placeId];
}
