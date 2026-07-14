# Maps Platform — Animations

## Purpose
Smooth map overlay animations for radius changes and camera following.

## AnimatedCircleOverlay
Wraps `TweenAnimationBuilder<double>` to smoothly interpolate a circle overlay radius.

```dart
AnimatedCircleOverlay(
  center: state.position,
  radiusKm: state.radiusKm,
  strokeColor: colors.primary,
  style: const RadiusOverlayStyle(
    circleId: 'coverage',
    strokeWidth: 4,
  ),
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeInOut,
  builder: (circles) => AppGoogleMap(
    circles: circles,
    // ...
  ),
)
```

**Parameters:**
- `center` — Circle center (null → empty circle set)
- `radiusKm` — Target radius in kilometers
- `strokeColor` — Circle stroke color
- `style` — `RadiusOverlayStyle` (circleId, strokeWidth, fillAlpha)
- `duration` — Animation duration (default 300ms)
- `curve` — Animation curve (default easeInOut)
- `builder` — Receives animated `Set<Circle>`

## MapCameraFollower
Auto-follows a position stream with camera animation.

```dart
final follower = MapCameraFollower(cameraController, zoom: 16);

// Start following
follower.follow(locationStream);

// Check state
follower.isFollowing.value; // true

// Stop following
follower.stop();
```

**Parameters:**
- `cameraController` — Target camera to animate
- `zoom` — Optional fixed zoom level during following

## Best Practices
- Use `AnimatedCircleOverlay` instead of rebuilding circles manually
- Always call `dispose()` on `MapCameraFollower`
- `follow()` automatically stops any previous subscription
