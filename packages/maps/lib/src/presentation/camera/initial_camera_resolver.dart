import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/presentation/camera/default_map_viewport.dart';

/// Resolves the initial map camera for provider location pickers using a fixed
/// priority, so no screen hardcodes this behavior:
///
/// 1. [existingLocation] — a saved location (edit flow)
/// 2. [initialLocation]  — an explicit location supplied by the caller
/// 3. [DefaultMapViewport] — the UAE default (centered on Dubai)
///
/// The device's current location is deliberately NOT part of this resolution:
/// it is applied only when the user explicitly taps "Use My Current Location".
abstract final class InitialCameraResolver {
  InitialCameraResolver._();

  /// The location to pin/select on open, by priority: saved → explicit.
  ///
  /// Returns `null` when the caller supplied neither — the map then opens on
  /// the [DefaultMapViewport] with no pin, and the provider chooses a location
  /// by panning, searching, or tapping "Use My Current Location".
  static LatLng? resolveInitialLocation({
    LatLng? existingLocation,
    LatLng? initialLocation,
  }) => existingLocation ?? initialLocation;

  /// The initial camera: saved → explicit → UAE default.
  static CameraPosition resolveCamera({
    LatLng? existingLocation,
    LatLng? initialLocation,
    double? zoom,
  }) {
    final target = resolveInitialLocation(
      existingLocation: existingLocation,
      initialLocation: initialLocation,
    );
    if (target == null) {
      return zoom == null
          ? DefaultMapViewport.camera
          : CameraPosition(target: DefaultMapViewport.center, zoom: zoom);
    }
    return CameraPosition(
      target: target,
      zoom: zoom ?? DefaultMapViewport.defaultZoom,
    );
  }
}
