import 'package:maps/maps.dart';

/// Converts a generic [MapAreaPickerResult] into a branch [ServingArea].
///
/// Branches owns the fallback when Maps returns no real Place ID.
ServingArea servingAreaFromPickerResult(MapAreaPickerResult result) {
  return ServingArea(
    placeId: result.placeId ?? result.address,
    name: result.title,
    address: result.address,
    latLng: result.position,
  );
}
