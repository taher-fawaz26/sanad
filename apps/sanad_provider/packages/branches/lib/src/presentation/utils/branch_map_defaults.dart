import 'package:maps/maps.dart';

/// Shared map defaults for the branch location-picker and coverage screens.
abstract final class BranchMapDefaults {
  BranchMapDefaults._();

  /// Fallback camera target (UAE, centered on Dubai) shown before a real
  /// position is resolved. Sourced from the shared [DefaultMapViewport] so the
  /// provider default lives in one place.
  static const LatLng position = DefaultMapViewport.center;

  /// Zoom used by the draggable location-picker map.
  static const double pickerZoom = 14;

  /// Zoom used by the coverage-area preview map (wider, to show the radius).
  static const double coverageZoom = 12.5;
}
