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
      cameraController: controller,
      getCurrentLocationUseCase: useCase,
    ),
    MapTypeButton(
      currentType: mapType,
      onChanged: (type) => setState(() => mapType = type),
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
GPS "my location" button with loading state.
- Calls `GetCurrentLocationUseCase` on tap
- Animates camera to current position
- Shows `CircularProgressIndicator` while loading
- Prevents duplicate taps during loading

## MapTypeButton
Toggle between `MapType.normal` and `MapType.satellite`.
- Shows contextual icons (satellite_alt / map_outlined)
- Calls `onChanged` with the next map type

## Best Practices
- Wrap controls in `MapControlBar` for consistent positioning
- Place `MapControlBar` inside a `Stack` alongside `AppGoogleMap`
- Use `Alignment.topRight` (default) for standard control placement
