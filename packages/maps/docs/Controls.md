# Maps Platform — Controls

## Purpose
Reusable map control widgets that compose with any map view.

## MapControlBar
Container that positions control buttons on the map.

```dart
MapControlBar(
  alignment: Alignment.topRight,  // default
  children: [
    MapZoomControls(cameraController: controller),
    MapMyLocationButton(
      isLoading: state.isLocating,
      onPressed: () =>
          bloc.add(const LocationPickerCurrentLocationRequested()),
    ),
  ],
)
```

## MapZoomControls
Zoom in/out buttons with min/max guards.
- Listens to `cameraController.zoom` via `ValueListenableBuilder`
- Disables buttons at zoom boundaries
- Uses `AppIconButton` + `AppShadows.small` from design system

## MapMyLocationButton
Presentational GPS "my location" (crosshair) button.
- Purely presentational: renders a spinner when `isLoading`, otherwise the
  crosshair icon, and delegates the tap via `onPressed`.
- Owns **no** location logic. The whole current-location sequence —
  permission/service resolution, GPS fetch, supported-area validation, camera
  move, reverse-geocode, retry and lifecycle recovery — lives in
  `LocationPickerBloc` (`LocationPickerCurrentLocationRequested`), so there is a
  single state machine and one in-flight guard. A failed attempt never
  clobbers a valid selection; it surfaces via `state.currentLocationFailure`
  (inline panel when no selection, transient snackbar when one exists). See
  SAN-778.

## Best Practices
- Wrap controls in `MapControlBar` for consistent positioning
- Place `MapControlBar` inside a `Stack` alongside `AppGoogleMap`
- Use `Alignment.topRight` (default) for standard control placement

> Note: these control widgets are internal composition parts of the package's
> pickers and are not part of the public barrel (`package:maps/maps.dart`).
