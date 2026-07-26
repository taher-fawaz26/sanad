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
    this.scrollGesturesEnabled = true,
    this.zoomGesturesEnabled = true,
    this.tiltGesturesEnabled = true,
    this.rotateGesturesEnabled = true,
    this.mapType = MapType.normal,
    this.padding = EdgeInsets.zero,
    this.cameraTargetBounds = CameraTargetBounds.unbounded,
    this.minMaxZoomPreference = MinMaxZoomPreference.unbounded,
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
  final bool scrollGesturesEnabled;
  final bool zoomGesturesEnabled;
  final bool tiltGesturesEnabled;
  final bool rotateGesturesEnabled;
  final MapType mapType;
  final EdgeInsets padding;

  /// Constrains the camera target so the map cannot be panned outside these
  /// bounds. Pickers pass [DefaultMapViewport.uaeBounds] to keep selection
  /// inside the UAE. Defaults to unbounded for read-only/embedded maps.
  final CameraTargetBounds cameraTargetBounds;

  /// Constrains the zoom range. Defaults to unbounded.
  final MinMaxZoomPreference minMaxZoomPreference;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  /// Claims pan/zoom gestures eagerly so the map stays interactive when it is
  /// embedded inside a scrolling parent (bottom sheets, scroll views).
  static const eagerGestureRecognizers =
      <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
      };

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
      scrollGesturesEnabled: scrollGesturesEnabled,
      zoomGesturesEnabled: zoomGesturesEnabled,
      tiltGesturesEnabled: tiltGesturesEnabled,
      rotateGesturesEnabled: rotateGesturesEnabled,
      mapType: mapType,
      padding: padding,
      cameraTargetBounds: cameraTargetBounds,
      minMaxZoomPreference: minMaxZoomPreference,
      gestureRecognizers: gestureRecognizers ?? eagerGestureRecognizers,
    );
  }
}
