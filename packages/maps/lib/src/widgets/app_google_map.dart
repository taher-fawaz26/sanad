import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Reusable Google Map with sensible defaults for Sanad location pickers.
class AppGoogleMap extends StatelessWidget {
  const AppGoogleMap({
    required this.initialCameraPosition,
    this.markers = const <Marker>{},
    this.circles = const <Circle>{},
    this.polygons = const <Polygon>{},
    this.polylines = const <Polyline>{},
    this.onMapCreated,
    this.onTap,
    this.onLongPress,
    this.onCameraMove,
    this.onCameraIdle,
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = false,
    this.zoomControlsEnabled = false,
    this.mapToolbarEnabled = false,
    this.compassEnabled = true,
    this.mapType = MapType.normal,
    this.padding = EdgeInsets.zero,
    this.gestureRecognizers,
    super.key,
  });

  final CameraPosition initialCameraPosition;
  final Set<Marker> markers;
  final Set<Circle> circles;
  final Set<Polygon> polygons;
  final Set<Polyline> polylines;
  final MapCreatedCallback? onMapCreated;
  final ArgumentCallback<LatLng>? onTap;
  final ArgumentCallback<LatLng>? onLongPress;
  final CameraPositionCallback? onCameraMove;
  final VoidCallback? onCameraIdle;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final bool zoomControlsEnabled;
  final bool mapToolbarEnabled;
  final bool compassEnabled;
  final MapType mapType;
  final EdgeInsets padding;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: initialCameraPosition,
      markers: markers,
      circles: circles,
      polygons: polygons,
      polylines: polylines,
      onMapCreated: onMapCreated,
      onTap: onTap,
      onLongPress: onLongPress,
      onCameraMove: onCameraMove,
      onCameraIdle: onCameraIdle,
      myLocationEnabled: myLocationEnabled,
      myLocationButtonEnabled: myLocationButtonEnabled,
      zoomControlsEnabled: zoomControlsEnabled,
      mapToolbarEnabled: mapToolbarEnabled,
      compassEnabled: compassEnabled,
      mapType: mapType,
      padding: padding,
      gestureRecognizers:
          gestureRecognizers ?? const <Factory<OneSequenceGestureRecognizer>>{},
    );
  }
}
