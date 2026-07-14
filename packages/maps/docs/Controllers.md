# Maps Platform — Controllers

## Purpose
Stateful camera and overlay management that abstracts away `GoogleMapController` internals.

## MapCameraController
Wraps `GoogleMapController` with `ValueListenable` observables for position, zoom, and animation state.

**Key methods:**
- `animateTo(LatLng, {zoom})` — Move camera with animation
- `fitBounds(MapRegion, {padding})` — Fit camera to bounding box
- `fitMarkers(Iterable<LatLng>, {padding})` — Fit camera to marker set
- `fitCircle(LatLng, {radiusKm, padding})` — Fit camera to circle
- `zoomIn()` / `zoomOut()` / `zoomTo(double)` — Zoom controls
- `onMapCreated(GoogleMapController)` — Bind to map widget
- `onCameraMove(CameraPosition)` — Update observables during gestures

**Observables:**
- `position` → `ValueListenable<LatLng?>`
- `zoom` → `ValueListenable<double>`
- `isAnimating` → `ValueListenable<bool>`

## MapRadiusController
Manages a center point and radius, produces `Circle` overlays and `LatLngBounds`.

**Key methods:**
- `update({center, radiusKm})` — Batch update with single notification
- `buildCircles({strokeColor, style})` — Generate `Set<Circle>` for the map
- `bounds` → `LatLngBounds?` via `GeoMath.boundsForRadius`

## MapOverlayController
CRUD operations for markers, polygons, and polylines with single-notification `clearAll()`.

**Key methods:**
- `addMarker` / `removeMarker` / `setMarkers` / `clearMarkers`
- `buildPolygon` / `removePolygon` / `setPolygons` / `clearPolygons`
- `buildPolyline` / `removePolyline` / `setPolylines` / `clearPolylines`
- `clearAll()` — Single notification for all three
- `markerById(MarkerId)` — Lookup

## MapCameraFollower
Subscribes to a `Stream<LatLng>` and auto-animates the camera.

**Key methods:**
- `follow(Stream<LatLng>)` — Start following (replaces previous stream)
- `stop()` — Cancel subscription
- `isFollowing` → `ValueListenable<bool>`

## Best Practices
- Always call `dispose()` on controllers in your widget's `dispose()`
- Use `MapCameraController` instead of raw `GoogleMapController`
- Prefer `update()` over setting `center`/`radiusKm` separately for batched notifications
- Check `isAnimating` before processing `onCameraIdle` to ignore programmatic moves
