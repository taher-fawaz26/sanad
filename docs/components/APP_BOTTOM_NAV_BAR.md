# AppBottomNavBar

Notch bottom navigation bar with 5 items and a center floating action button.
Built on the Sanad fork of `curved_navigation_bar_pro` at
[`packages/curved_navigation_bar_pro`](../../packages/curved_navigation_bar_pro).

Figma reference: `Nab-Bar` (`3148:27106`)
Dribbble reference: Notch bottom navigation design

## Features

- **5 navigation items** — 2 before center, 2 after center, 1 extra slot
- **Center floating action** — elevated button with custom tap handler
- **Smooth animations** — icon scale, opacity, and notch movement
- **Full package API usage** — uses `CurvedNavigationBarPro` with SVG widgets
- **Theme-aware** — light/dark mode support via design tokens
- **RTL support** — the forked package mirrors FAB/notch physical X under
  ambient `Directionality`. Callers always use semantic visual indices
  (`0` = leading / Home). No app-layer index remapping.
- **SVG icons** — loaded via `AppSvgPicture` from `app_assets`

## Import

```dart
import 'package:design_system/design_system.dart';
import 'package:app_assets/app_assets.dart';
```

## Required Setup

1. Pass exactly 5 items via the `items` parameter (index `2` = center slot)
2. Wire selection through `currentIndex` and `onTap`
3. Provide center FAB configuration via `centerAction`

## Provider app integration

`sanad_provider` maps bar indices, shell branches, and routes from a single
enum — [ProviderBottomNavDestination] — in
`apps/sanad_provider/lib/src/routing/shell/provider_bottom_nav.dart`.

Visual order: **Home · Messages · Requests (center FAB) · Services · Settings**.

`MainShell` must not hardcode index conversions; use
`ProviderBottomNavDestination.fromBarIndex` /
`ProviderBottomNavDestination.fromShellBranch` instead.

## Example (design catalog / generic)

```dart
class MainShell extends StatelessWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(index),
        centerAction: AppBottomNavCenterAction(
          iconAsset: AppNavigationIcons.centerAction,
          semanticLabel: 'nav.requests'.tr(),
          onTap: () => navigationShell.goBranch(2),
        ),
        items: [
          AppBottomNavItem(
            iconAsset: AppNavigationIcons.home,
            label: 'nav.home'.tr(),
          ),
          AppBottomNavItem(
            iconAsset: AppNavigationIcons.messages,
            label: 'nav.messages'.tr(),
          ),
          AppBottomNavItem(
            iconAsset: AppNavigationIcons.centerAction,
            label: 'nav.requests'.tr(),
          ),
          AppBottomNavItem(
            iconAsset: AppNavigationIcons.service,
            label: 'nav.service'.tr(),
          ),
          AppBottomNavItem(
            iconAsset: AppNavigationIcons.settings,
            label: 'nav.settings'.tr(),
          ),
        ],
      ),
    );
  }
}
```

## API

### AppBottomNavBar

| Parameter | Type | Description |
|-----------|------|-------------|
| `items` | `List<AppBottomNavItem>` | Exactly 5 navigation items |
| `currentIndex` | `int` | Currently selected item index (0-4) |
| `onTap` | `ValueChanged<int>` | Called when an item is tapped (receives index 0-4) |
| `centerAction` | `AppBottomNavCenterAction` | Configuration for the center floating action button |

### AppBottomNavItem

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `iconAsset` | `String` | required | SVG icon path from `AppNavigationIcons` |
| `label` | `String` | required | Visible label below icon |
| `semanticLabel` | `String?` | `null` | Accessibility label; defaults to `label` |
| `enabled` | `bool` | `true` | Whether this item can be tapped |

### AppBottomNavCenterAction

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `iconAsset` | `String` | required | SVG icon path for center button |
| `semanticLabel` | `String?` | `null` | Accessibility label |
| `onTap` | `VoidCallback?` | `null` | Tap handler for center button |
| `selected` | `bool` | `false` | Whether button is in selected state (changes color) |
| `enabled` | `bool` | `true` | Whether button can be tapped |

## Behavior

- **Navigation** — The component is generic and has no route knowledge; the caller owns all navigation logic
- **Center notch** — Always locked to index 2; the controller is kept at center automatically
- **Disabled items** — Dimmed and ignore taps when `enabled: false`
- **Text scaling** — Tab labels use fixed 12sp for layout stability; semantic labels remain available at all text scales
- **Animations** — Uses `AnimatedScale`, `AnimatedOpacity`, and `AnimatedContainer` for smooth transitions

## Package Features Used

The implementation wraps `CurvedNavigationBarPro` with Sanad tokens and SVG items:

- `CurvedNavigationBarPro` — animated curved notch + elastic FAB bubble
- `CurvedNavigationItemPro.inactiveWidget` / `activeWidget` — SVG icons via `AppSvgPicture`
- `backgroundColor`, `fabColor`, `activeColor`, `inactiveColor` — from `BottomNavTokens`
- `barHeight`, `fabRadius`, `fabGap`, `fabSink`, `cornerRadius` — Figma geometry
- `animationDuration`, `animationCurve` — from `AppDurations.notchBar`

## Design Tokens

All styling is controlled via `BottomNavTokens`:

### Layout Tokens
- `bottomBarHeight: 72.0` — bar height
- `kBottomRadius: 28.0` — top corner radius
- `kIconSize: 24.0` — icon size
- `circleMargin: 8.0` — FAB/notch gap
- `fabSink: 20.0` — FAB vertical sink
- `centerFabSize: 52.0` — center bubble diameter

### Color Tokens
- `backgroundColor()` — bar background (theme-dependent)
- `selectedIconColor()` — selected item color
- `unselectedIconColor()` — unselected item color
- `disabledIconColor()` — disabled item color
- `centerFabActiveColor()` — active FAB color
- `centerFabInactiveColor()` — inactive FAB color

### Animation Tokens
- `durationInMilliSeconds: 450` — from `AppDurations.notchBar`
- `animationCurve: Curves.easeOutCubic` — animation easing

## Preview

Run the design catalog:

```bash
cd apps/design_catalog
flutter run
```

Navigate to **Navigation → AppBottomNavBar** to preview:
- Light/dark themes
- Item selection states
- Center action states (selected/disabled)
- Disabled items
- RTL layout with Arabic labels
- Different text scale factors

## Testing

```bash
cd packages/design_system
flutter test test/src/components/app_bottom_nav_bar_test.dart
```

Tests cover:
- 5-item rendering
- Center action tap
- Item tap callbacks
- Disabled item behavior
- Dark theme rendering
- Text scale factors (1.0x - 2.0x)

## Migration from Old Implementation

**Old API (4 items with `leadingCount`)**:
```dart
AppBottomNavBar(
  controller: controller,
  leadingCount: 2,  // ❌ No longer needed
  items: [item1, item2, item3, item4],  // ❌ Must be 5 items now
  // ...
)
```

**New API (5 items, center at index 2)**:
```dart
AppBottomNavBar(
  currentIndex: 2,
  items: [item1, item2, item3, item4, item5],  // ✅ Exactly 5 items
  centerAction: AppBottomNavCenterAction(...),
  // ...
)
```

Key changes:
- **5 items required** — no longer configurable count
- **No `leadingCount`** — center is always at index 2
- **No `textDirection` override** — uses ambient `Directionality`
- **Simpler API** — removed internal slot mapping complexity

## Package Notes

The Sanad fork of `curved_navigation_bar_pro` moves the FAB bubble to the
selected tab and maps list index → physical slot for RTL:

- LTR: index `0` → left
- RTL: index `0` → right (Row flips children; FAB/notch use mirrored X)

Index `2` remains the center action slot; use `centerAction` for its icon and
tap handler. Upstream: https://pub.dev/packages/curved_navigation_bar_pro

## References

- Fork: `packages/curved_navigation_bar_pro`
- Figma: `Nab-Bar` (`3148:27106`)
- Icons: `packages/app_assets/lib/src/app_navigation_icons.dart`
- Tokens: `packages/design_system/lib/src/theme/tokens/bottom_nav_tokens.dart`
