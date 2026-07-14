# Maps Platform — Public API

## Purpose

Single reference for all public types exported from `package:maps/maps.dart`.
The surface is intentionally small — only what features consume plus a few
documented extension points. Everything else is internal to the package.

## Configuration

| Type | Description |
|------|-------------|
| `MapsConfig` | Top-level config: `placesApiKey`, `placesProvider` (`PlacesProviderType`) |
| `PlacesProviderType` | Enum: `google`, `backend`, `openStreetMap` |
| `MapsDI` | Static `init()` for dependency injection setup |

## Entities

| Type | Description |
|------|-------------|
| `PlacePrediction` | Autocomplete result with `placeId`, `mainText`, `secondaryText` |
| `MapAreaPickerResult` | One picked area: `placeId?`, `areaName`, `address`, `position` |
| `ServingArea` | Generic named area value object: `placeId`, `name`, `address`, `latLng` |
| `CoverageMode` | Enum: `create`, `edit`, `recalculate` |

## Controllers

| Type | Description |
|------|-------------|
| `MapCameraController` | Camera abstraction: animate, zoom, fit bounds/markers/circle |
| `MapRadiusController` | Radius overlay: center + radius → circles + bounds |

## BLoCs

| Type | Description |
|------|-------------|
| `LocationPickerBloc` | Single-location selection with geocoding + optional Places autocomplete |
| `CoverageAreaBloc` | Coverage management: center, radius, auto areas, and a **list** of extra areas |

> `MapAreaPickerBloc` powers the area picker widget but is an internal detail —
> use `showMapAreaPicker` instead of constructing it directly.

## Widgets

| Type | Description |
|------|-------------|
| `AppGoogleMap` | Configured Google Map with eager gesture recognizers |
| `showLocationPickerSheet()` | Full-screen location picker bottom sheet → `LocationPickerResult?` |
| `showMapAreaPicker()` | Feature-agnostic single-area picker → `MapAreaPickerResult?` |
| `PlaceSearchBar` | Autocomplete search field with predictions dropdown |
| `ServingAreaChips` | Removable chips rendering a list of `ServingArea` |

## Models

| Type | Description |
|------|-------------|
| `LocationPickerLabels` / `LocationPickerResult` | Strings + result for the location picker |
| `MapAreaPickerLabels` | Strings for the area picker |
| `PlaceSearchStatus` | Enum: `idle`, `searching`, `success`, `empty`, `failure` |
| `RadiusOverlayStyle` | Circle overlay visual config |

## Utilities

| Type | Description |
|------|-------------|
| `formatRadiusKm(double)` | Locale-agnostic radius formatting |

## Services / Infrastructure (wired by the host app's DI)

| Type | Description |
|------|-------------|
| `LocationService` / `LocationServiceImpl` | GPS location + permissions |
| `GeocodingService` / `GeocodingServiceImpl` | Forward/reverse geocoding + nearby areas |

## Re-exported Google Maps Types

`LatLng`, `LatLngBounds`, `CameraPosition`, `CameraUpdate`, `MapType`,
`GoogleMapController`, `Marker`, `MarkerId`, `Circle`, `CircleId`, `Polygon`,
`PolygonId`, `Polyline`, `PolylineId`, `BitmapDescriptor`.

## Feature-agnostic principle

The maps package contains **no** business-feature concepts. Coverage editing
receives its previously-saved area names from the consuming feature via
`CoverageAreaStarted(initialAutoAreas: ...)`; the package never loads
feature-owned data itself.

## Examples

### Basic initialization

```dart
MapsDI.init(
  config: MapsConfig(
    placesApiKey: String.fromEnvironment('MAPS_API_KEY'),
    placesProvider: PlacesProviderType.google,
  ),
);
```

### Pick a single area

```dart
final result = await showMapAreaPicker(
  context,
  initialPosition: center,
  labels: MapAreaPickerLabels(/* ... */),
);
if (result != null) {
  // result.placeId / result.areaName / result.address / result.position
}
```
