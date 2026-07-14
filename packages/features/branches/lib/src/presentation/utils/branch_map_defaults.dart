import 'package:maps/maps.dart';

/// Shared map defaults for the branch location-picker and coverage screens.
abstract final class BranchMapDefaults {
  BranchMapDefaults._();

  /// Fallback camera target (Dubai) shown before a real position is resolved.
  static const LatLng position = LatLng(25.0772, 55.1396);

  /// Zoom used by the draggable location-picker map.
  static const double pickerZoom = 14;

  /// Zoom used by the coverage-area preview map (wider, to show the radius).
  static const double coverageZoom = 12.5;
}
