import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Generic result from the map area picker.
class MapAreaPickerResult extends Equatable {
  const MapAreaPickerResult({
    required this.title,
    required this.address,
    required this.position,
    this.placeId,
  });

  /// Null unless the user selected a real Google Places prediction.
  /// Never synthesized from address or coordinates.
  final String? placeId;
  final String title;
  final String address;
  final LatLng position;

  @override
  List<Object?> get props => [placeId, title, address, position];
}
