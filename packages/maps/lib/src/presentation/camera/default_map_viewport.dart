import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Single source of truth for the default map viewport used by every provider
/// location picker.
///
/// Providers may be physically outside the UAE while managing UAE businesses,
/// so pickers must open on the UAE (centered on Dubai) rather than the device's
/// GPS location. This viewport is the priority-3 fallback in
/// [InitialCameraResolver] (saved → explicit → **this**).
abstract final class DefaultMapViewport {
  DefaultMapViewport._();

  /// Default center — Dubai. Chosen as a neutral, dense UAE anchor.
  static const LatLng center = LatLng(25.0772, 55.1396);

  /// Default zoom when opening on the UAE viewport.
  static const double defaultZoom = 14;

  /// Approximate national bounds of the UAE.
  ///
  /// The interactive pickers pass these to [AppGoogleMap.cameraTargetBounds]
  /// so the camera cannot be panned outside the UAE — providers may only
  /// select places inside the country.
  static final LatLngBounds uaeBounds = LatLngBounds(
    southwest: const LatLng(22.5, 51.0),
    northeast: const LatLng(26.5, 56.5),
  );

  /// The full default camera (UAE, centered on Dubai) at [defaultZoom].
  static const CameraPosition camera = CameraPosition(
    target: center,
    zoom: defaultZoom,
  );
}
