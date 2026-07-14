import 'package:maps/maps.dart';

/// Converts a generic [MapAreaPickerResult] into a branch [ServingArea].
///
/// When Maps returns no real Place ID (e.g. the user tapped the map instead of
/// choosing an autocomplete prediction), we derive a stable id from the picked
/// coordinates rather than the address. Keying on the address caused distinct
/// picks that reverse-geocode to the same street/city to collapse into one
/// identity, so a second manual area silently deduplicated against the first.
ServingArea servingAreaFromPickerResult(MapAreaPickerResult result) {
  return ServingArea(
    placeId: result.placeId ?? _coordinateKey(result.position),
    name: result.title,
    address: result.address,
    latLng: result.position,
  );
}

String _coordinateKey(LatLng position) =>
    'latlng:${position.latitude},${position.longitude}';
