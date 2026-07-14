# Maps Platform — Drawing Engine

## Purpose
Typed CRUD management for map overlays (markers, polygons, polylines) with efficient notification batching.

## MapOverlayController

### Markers
- `addMarker(Marker)` — Add with notification
- `removeMarker(MarkerId)` — Remove by ID (no-op if missing, no notification)
- `setMarkers(Set<Marker>)` — Replace all
- `clearMarkers()` — Clear all (no notification if already empty)
- `markerById(MarkerId)` — Lookup, returns null if not found

### Polygons
- `buildPolygon({id, points, style})` — Create, add, and return a `Polygon`
- `removePolygon(PolygonId)` — Remove by ID
- `setPolygons(Set<Polygon>)` / `clearPolygons()`

### Polylines
- `buildPolyline({id, points, style})` — Create, add, and return a `Polyline`
- `removePolyline(PolylineId)` / `setPolylines(Set<Polyline>)` / `clearPolylines()`

### Batch Operations
- `clearAll()` — Clears markers + polygons + polylines in a single notification

## Style Models

### PolygonStyle
```dart
const PolygonStyle(
  strokeWidth: 2,    // default
  strokeColor: color,
  fillColor: color,
  geodesic: false,   // default
)
```

### PolylineStyle
```dart
const PolylineStyle(
  width: 4,          // default
  color: color,
  geodesic: false,   // default
  patterns: [],      // default
)
```

## Radius Overlays

### MapRadiusController
- Manages center + radiusKm → `Set<Circle>`
- `buildCircles({strokeColor, style})` with `RadiusOverlayStyle`
- `bounds` computed via `GeoMath.boundsForRadius`

### AnimatedCircleOverlay Widget
- Smooth radius animation via `TweenAnimationBuilder<double>`
- Configurable duration (default 300ms) and curve (default easeInOut)

## Best Practices
- Use `MapOverlayController` instead of managing `Set<Marker>` manually
- Use `buildPolygon`/`buildPolyline` convenience methods for consistent styling
- Prefer `clearAll()` over clearing each type separately
- Use `AnimatedCircleOverlay` for smooth radius transitions
