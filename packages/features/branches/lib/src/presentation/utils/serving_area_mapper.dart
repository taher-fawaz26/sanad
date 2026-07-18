import 'package:maps/maps.dart';

/// Converts a generic [MapAreaPickerResult] into a branch [ServingArea].
///
/// Only results with a real Google Place ID are accepted — the backend
/// validates place IDs against its own area registry and rejects synthetic
/// coordinate-based identifiers.
///
/// Returns `null` when the result carries no place ID (e.g. the user tapped
/// the map rather than selecting an autocomplete prediction).
ServingArea? servingAreaFromPickerResult(MapAreaPickerResult result) {
  if (result.placeId == null) return null;
  return ServingArea(
    placeId: result.placeId!,
    name: result.areaName,
    address: result.address,
    latLng: result.position,
  );
}
