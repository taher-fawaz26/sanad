import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/map_region.dart';

/// Abstraction over `GoogleMapController` for camera operations.
///
/// Business features use this instead of `GoogleMapController` directly.
/// Bind it to a map widget via [onMapCreated] and release via [dispose].
/// All operations are no-ops while no controller is bound.
class MapCameraController {
  GoogleMapController? _controller;

  final _position = ValueNotifier<LatLng?>(null);
  final _zoom = ValueNotifier<double>(14);
  final _isAnimating = ValueNotifier<bool>(false);

  ValueListenable<LatLng?> get position => _position;
  ValueListenable<double> get zoom => _zoom;
  ValueListenable<bool> get isAnimating => _isAnimating;

  bool get isAttached => _controller != null;

  /// Call from the map widget's `onMapCreated` callback.
  // ignore: use_setters_to_change_properties
  void onMapCreated(GoogleMapController controller) {
    _controller = controller;
  }

  Future<void> animateTo(
    LatLng target, {
    double? zoom,
  }) async {
    final controller = _controller;
    if (controller == null) return;

    _isAnimating.value = true;
    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: zoom ?? _zoom.value),
        ),
      );
      _position.value = target;
      if (zoom != null) _zoom.value = zoom;
    } finally {
      _isAnimating.value = false;
    }
  }

  Future<void> fitBounds(
    MapRegion region, {
    double padding = 48,
  }) async {
    final controller = _controller;
    if (controller == null) return;

    _isAnimating.value = true;
    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: region.southwest,
            northeast: region.northeast,
          ),
          padding,
        ),
      );
      _position.value = region.center;
    } finally {
      _isAnimating.value = false;
    }
  }

  Future<void> fitMarkers(
    Iterable<LatLng> positions, {
    double padding = 64,
  }) async {
    if (positions.isEmpty) return;
    if (positions.length == 1) {
      return animateTo(positions.first);
    }

    var minLat = positions.first.latitude;
    var maxLat = positions.first.latitude;
    var minLng = positions.first.longitude;
    var maxLng = positions.first.longitude;

    for (final p in positions) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return fitBounds(
      MapRegion(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
      padding: padding,
    );
  }

  Future<void> fitCircle(
    LatLng center, {
    required double radiusKm,
    double padding = 48,
  }) async {
    final offset = radiusKm / 111.32;
    return fitBounds(
      MapRegion(
        southwest: LatLng(
          center.latitude - offset,
          center.longitude - offset,
        ),
        northeast: LatLng(
          center.latitude + offset,
          center.longitude + offset,
        ),
      ),
      padding: padding,
    );
  }

  Future<void> zoomTo(double zoom) async {
    final controller = _controller;
    if (controller == null) return;

    await controller.animateCamera(CameraUpdate.zoomTo(zoom));
    _zoom.value = zoom;
  }

  Future<void> zoomIn() async {
    final controller = _controller;
    if (controller == null) return;

    await controller.animateCamera(CameraUpdate.zoomIn());
    _zoom.value = _zoom.value + 1;
  }

  Future<void> zoomOut() async {
    final controller = _controller;
    if (controller == null) return;

    await controller.animateCamera(CameraUpdate.zoomOut());
    _zoom.value = _zoom.value - 1;
  }

  void onCameraMove(CameraPosition cameraPosition) {
    _position.value = cameraPosition.target;
    _zoom.value = cameraPosition.zoom;
  }

  void dispose() {
    _controller = null;
    _position.dispose();
    _zoom.dispose();
    _isAnimating.dispose();
  }
}
