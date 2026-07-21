import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/presentation/camera/default_map_viewport.dart';

/// Configurable defaults for maps platform widgets.
///
/// Business features create a [MapConfiguration] and pass it to platform
/// widgets instead of hardcoding values.
class MapConfiguration {
  const MapConfiguration({
    this.initialPosition = DefaultMapViewport.center,
    this.initialZoom = DefaultMapViewport.defaultZoom,
    this.minZoom,
    this.maxZoom,
    this.mapType = MapType.normal,
    this.compassEnabled = true,
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = false,
    this.zoomControlsEnabled = false,
    this.mapToolbarEnabled = false,
    this.scrollGesturesEnabled = true,
    this.zoomGesturesEnabled = true,
    this.tiltGesturesEnabled = true,
    this.rotateGesturesEnabled = true,
    this.padding = EdgeInsets.zero,
    this.locale,
  });

  final LatLng initialPosition;
  final double initialZoom;
  final double? minZoom;
  final double? maxZoom;
  final MapType mapType;
  final bool compassEnabled;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final bool zoomControlsEnabled;
  final bool mapToolbarEnabled;
  final bool scrollGesturesEnabled;
  final bool zoomGesturesEnabled;
  final bool tiltGesturesEnabled;
  final bool rotateGesturesEnabled;
  final EdgeInsets padding;
  final String? locale;

  MapConfiguration copyWith({
    LatLng? initialPosition,
    double? initialZoom,
    double? minZoom,
    double? maxZoom,
    MapType? mapType,
    bool? compassEnabled,
    bool? myLocationEnabled,
    bool? myLocationButtonEnabled,
    bool? zoomControlsEnabled,
    bool? mapToolbarEnabled,
    bool? scrollGesturesEnabled,
    bool? zoomGesturesEnabled,
    bool? tiltGesturesEnabled,
    bool? rotateGesturesEnabled,
    EdgeInsets? padding,
    String? locale,
  }) {
    return MapConfiguration(
      initialPosition: initialPosition ?? this.initialPosition,
      initialZoom: initialZoom ?? this.initialZoom,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      mapType: mapType ?? this.mapType,
      compassEnabled: compassEnabled ?? this.compassEnabled,
      myLocationEnabled: myLocationEnabled ?? this.myLocationEnabled,
      myLocationButtonEnabled:
          myLocationButtonEnabled ?? this.myLocationButtonEnabled,
      zoomControlsEnabled: zoomControlsEnabled ?? this.zoomControlsEnabled,
      mapToolbarEnabled: mapToolbarEnabled ?? this.mapToolbarEnabled,
      scrollGesturesEnabled:
          scrollGesturesEnabled ?? this.scrollGesturesEnabled,
      zoomGesturesEnabled: zoomGesturesEnabled ?? this.zoomGesturesEnabled,
      tiltGesturesEnabled: tiltGesturesEnabled ?? this.tiltGesturesEnabled,
      rotateGesturesEnabled:
          rotateGesturesEnabled ?? this.rotateGesturesEnabled,
      padding: padding ?? this.padding,
      locale: locale ?? this.locale,
    );
  }
}
