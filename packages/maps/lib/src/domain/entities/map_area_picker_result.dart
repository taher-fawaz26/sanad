import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Generic result from the map area picker.
class MapAreaPickerResult extends Equatable {
  const MapAreaPickerResult({
    required this.areaName,
    required this.address,
    required this.position,
    this.placeId,
  });

  /// Null unless the user selected a real Google Places prediction.
  /// Never synthesized from address or coordinates.
  final String? placeId;

  /// Human-friendly area/neighborhood name suitable for display as a label
  /// (e.g. "Dubai Marina"), rather than the full street address.
  final String areaName;

  /// The full formatted address of the picked point (kept for detail views;
  /// not intended as the display label).
  final String address;
  final LatLng position;

  @override
  List<Object?> get props => [placeId, areaName, address, position];
}
