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

## ServingAreaController
Generic ordered set with value-based de-duplication. Backs the coverage bloc's
auto-area and extra-area lists (`add`/`remove`/`replace`/`contains`).

## Best Practices
- Always call `dispose()` on controllers in your widget's `dispose()`
- Use `MapCameraController` instead of raw `GoogleMapController`
- Prefer `update()` over setting `center`/`radiusKm` separately for batched notifications
- Check `isAnimating` before processing `onCameraIdle` to ignore programmatic moves
