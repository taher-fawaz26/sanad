import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

sealed class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object?> get props => [];
}

final class MapReadyEvent extends MapEvent {
  const MapReadyEvent({required this.controller});

  final GoogleMapController controller;

  @override
  List<Object?> get props => [controller];
}

final class CameraMovedEvent extends MapEvent {
  const CameraMovedEvent({
    required this.position,
    required this.zoom,
    required this.bearing,
    required this.tilt,
  });

  factory CameraMovedEvent.fromCameraPosition(CameraPosition camera) {
    return CameraMovedEvent(
      position: camera.target,
      zoom: camera.zoom,
      bearing: camera.bearing,
      tilt: camera.tilt,
    );
  }

  final LatLng position;
  final double zoom;
  final double bearing;
  final double tilt;

  @override
  List<Object?> get props => [position, zoom, bearing, tilt];
}

final class CameraIdleEvent extends MapEvent {
  const CameraIdleEvent({required this.position, required this.zoom});

  final LatLng position;
  final double zoom;

  @override
  List<Object?> get props => [position, zoom];
}

final class MarkerSelectedEvent extends MapEvent {
  const MarkerSelectedEvent({required this.markerId, this.position});

  final MarkerId markerId;
  final LatLng? position;

  @override
  List<Object?> get props => [markerId, position];
}

final class PlaceSelectedEvent extends MapEvent {
  const PlaceSelectedEvent({
    required this.position,
    this.address,
    this.placeId,
  });

  final LatLng position;
  final String? address;
  final String? placeId;

  @override
  List<Object?> get props => [position, address, placeId];
}

final class RadiusChangedEvent extends MapEvent {
  const RadiusChangedEvent({
    required this.center,
    required this.radiusKm,
  });

  final LatLng center;
  final double radiusKm;

  @override
  List<Object?> get props => [center, radiusKm];
}

final class MapTappedEvent extends MapEvent {
  const MapTappedEvent({required this.position});

  final LatLng position;

  @override
  List<Object?> get props => [position];
}

final class MapLongPressedEvent extends MapEvent {
  const MapLongPressedEvent({required this.position});

  final LatLng position;

  @override
  List<Object?> get props => [position];
}
