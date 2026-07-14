# Maps Platform — Public API

## Purpose

Single reference for all public types exported from `package:maps/maps.dart`.

## Configuration

| Type | Description |
|------|-------------|
| `MapsConfig` | Top-level config: `placesApiKey`, `placesProvider` (PlacesProviderType) |
| `PlacesProviderType` | Enum: `google`, `backend`, `openStreetMap` |
| `MapConfiguration` | Widget-level map defaults: position, zoom, gestures, padding |
| `MapsDI` | Static `init()` for dependency injection setup |

## Entities

| Type | Description |
|------|-------------|
| `MapPosition` | Geographic position value object |
| `MapRegion` | Bounding box with `southwest`/`northeast` corners |
| `PlacePrediction` | Autocomplete result with `placeId`, `mainText`, `secondaryText` |

## Map Events

| Type | Description |
|------|-------------|
| `MapReadyEvent` | Fired when the map controller is ready |
| `CameraMovedEvent` | Camera position/zoom change during gesture |
| `CameraIdleEvent` | Camera settled after movement |
| `MarkerSelectedEvent` | Marker tapped |
| `PlaceSelectedEvent` | Place chosen (position + optional address/placeId) |
| `RadiusChangedEvent` | Coverage radius changed |
| `MapTappedEvent` | Map surface tapped |
| `MapLongPressedEvent` | Map surface long-pressed |

## Failures

| Type | Extends | Description |
|------|---------|-------------|
| `PlacesApiKeyFailure` | `ServerFailure` | Invalid or missing API key |
| `PlacesQuotaExceededFailure` | `ServerFailure` | API quota exceeded |
| `PlacesNetworkFailure` | `NetworkFailure` | Network-level request failure |
| `PlacesTimeoutFailure` | `TimeoutFailure` | Request timed out |
| `PlacesInvalidRequestFailure` | `ServerFailure` | Malformed request |
| `PlacesUnknownFailure` | `UnknownFailure` | Unclassified Places error |

## Use Cases

| Type | Params | Result |
|------|--------|--------|
| `GetCurrentLocationUseCase` | `NoParams` | `LatLng` |
| `OpenLocationSettingsUseCase` | `NoParams` | `void` |
| `ReverseGeocodeUseCase` | `ReverseGeocodeParams` | `String` (address) |
| `ForwardGeocodeUseCase` | `ForwardGeocodeParams` | `LatLng` |
| `GetNearbyAreasUseCase` | `NearbyAreasParams` | `List<String>` |
| `SearchPlacesUseCase` | `SearchPlacesParams` | `List<PlacePrediction>` |
| `GetPlaceDetailsUseCase` | `GetPlaceDetailsParams` | `LatLng` |

## Controllers

| Type | Description |
|------|-------------|
| `MapCameraController` | Camera abstraction: animate, zoom, fit bounds/markers/circle |
| `MapRadiusController` | Radius overlay: center + radius → circles + bounds |
| `MapOverlayController` | CRUD for markers, polygons, polylines |
| `MapCameraFollower` | Auto-follow a position stream with camera animation |

## BLoCs

| Type | Description |
|------|-------------|
| `LocationPickerBloc` | Location selection with geocoding, optional Places autocomplete |
| `CoverageAreaBloc` | Area management: position, radius, suggested/custom/removed areas |

## Widgets

| Type | Description |
|------|-------------|
| `AppGoogleMap` | Configured Google Map with eager gesture recognizers |
| `showLocationPickerSheet()` | Full location picker bottom sheet |
| `CoverageAreaPicker` | Composite: map + radius selector + area list + confirm |
| `PlaceSearchBar` | Autocomplete search with predictions dropdown |
| `RadiusSelector` | Slider + optional preset chips |
| `NearbyPlacesSheet` | List of nearby places with remove support |
| `MapControlBar` | Positioned container for map control buttons |
| `MapZoomControls` | Zoom in/out buttons |
| `MapMyLocationButton` | Current location button |
| `MapTypeButton` | Normal/satellite toggle |
| `AnimatedCircleOverlay` | Smooth radius animation via TweenAnimationBuilder |

## Models

| Type | Description |
|------|-------------|
| `LocationPickerLabels` | Strings for location picker |
| `LocationPickerResult` | Selected position + address |
| `CoverageAreaLabels` | Strings for coverage area picker |
| `RadiusPreset` | Label + radiusKm for preset chips |
| `RadiusOverlayStyle` | Circle overlay visual config |
| `PolygonStyle` | Polygon visual config |
| `PolylineStyle` | Polyline visual config |

## Services / Providers

| Type | Description |
|------|-------------|
| `PlacesProvider` | Abstract Places interface |
| `GooglePlacesProvider` | Google Places API implementation (Dio-based) |
| `BackendPlacesProvider` | Backend API stub |
| `OsmPlacesProvider` | OpenStreetMap stub |

## Re-exported Google Maps Types

`LatLng`, `LatLngBounds`, `CameraPosition`, `CameraUpdate`, `MapType`, `GoogleMapController`, `Marker`, `MarkerId`, `Circle`, `CircleId`, `Polygon`, `PolygonId`, `Polyline`, `PolylineId`, `BitmapDescriptor`

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

### Show location picker

```dart
final result = await showLocationPickerSheet(
  context,
  labels: LocationPickerLabels(
    searchHint: 'Search location',
    confirm: 'Confirm',
    // ... other labels
  ),
);
if (result != null) {
  print('${result.position} — ${result.address}');
}
```
