import 'package:app_logger/app_logger.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Reusable Google Map with sensible defaults for Sanad location pickers.
///
/// Shows an [AppShimmer] overlay until the underlying platform view fires
/// [onMapCreated], then cross-fades to the live map surface.
class AppGoogleMap extends StatefulWidget {
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
  State<AppGoogleMap> createState() => _AppGoogleMapState();
}

class _AppGoogleMapState extends State<AppGoogleMap> {
  bool _mapReady = false;

  void _onMapCreated(GoogleMapController controller) {
    appLogger.d('[AppGoogleMap] onMapCreated — map ready');
    if (mounted) setState(() => _mapReady = true);
    widget.onMapCreated?.call(controller);
  }

  @override
  Widget build(BuildContext context) {
    appLogger.d('[AppGoogleMap] building GoogleMap (PlatformView requested)');
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: widget.initialCameraPosition,
          markers: widget.markers,
          circles: widget.circles,
          polygons: widget.polygons,
          polylines: widget.polylines,
          onMapCreated: _onMapCreated,
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onCameraMove: widget.onCameraMove,
          onCameraIdle: widget.onCameraIdle,
          myLocationEnabled: widget.myLocationEnabled,
          myLocationButtonEnabled: widget.myLocationButtonEnabled,
          zoomControlsEnabled: widget.zoomControlsEnabled,
          mapToolbarEnabled: widget.mapToolbarEnabled,
          compassEnabled: widget.compassEnabled,
          scrollGesturesEnabled: widget.scrollGesturesEnabled,
          zoomGesturesEnabled: widget.zoomGesturesEnabled,
          tiltGesturesEnabled: widget.tiltGesturesEnabled,
          rotateGesturesEnabled: widget.rotateGesturesEnabled,
          mapType: widget.mapType,
          padding: widget.padding,
          cameraTargetBounds: widget.cameraTargetBounds,
          minMaxZoomPreference: widget.minMaxZoomPreference,
          gestureRecognizers:
              widget.gestureRecognizers ?? AppGoogleMap.eagerGestureRecognizers,
        ),
        // Shimmer overlay — stays in front of the platform view until
        // onMapCreated fires, then fades out over 300 ms.
        AnimatedOpacity(
          opacity: _mapReady ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          // IgnorePointer so touches reach the map during the fade-out.
          child: IgnorePointer(
            ignoring: _mapReady,
            child: AppShimmer(
              child: Container(color: context.appColors.onBackground),
            ),
          ),
        ),
      ],
    );
  }
}
