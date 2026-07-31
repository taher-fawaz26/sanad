# AppBottomNavBar

Notch bottom navigation bar with 5 items and a center floating action button.
Built entirely on [`animated_notch_bottom_bar`](https://pub.dev/packages/animated_notch_bottom_bar) package.

Figma reference: `Nab-Bar` (`3148:27106`)
Dribbble reference: Notch bottom navigation design

## Features

- **5 navigation items** — 2 before center, 2 after center, 1 extra slot
- **Center floating action** — elevated button with custom tap handler
- **Smooth animations** — icon scale, opacity, and notch movement
- **Full package API usage** — uses all available `animated_notch_bottom_bar` features
- **Theme-aware** — light/dark mode support via design tokens
- **RTL support** — inherits from ambient `Directionality`
- **SVG icons** — loaded via `AppSvgPicture` from `app_assets`

## Import

```dart
import 'package:design_system/design_system.dart';
import 'package:app_assets/app_assets.dart';
```

## Required Setup

1. Create a `NotchBottomBarController` initialized with index 2 (center position)
2. Pass exactly 5 items via the `items` parameter
3. Wire selection through `currentIndex` and `onTap`
4. Provide center FAB configuration via `centerAction`

## Example

```dart
class MainShell extends StatefulWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late final NotchBottomBarController _controller =
      NotchBottomBarController(index: 2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        controller: _controller,
        currentIndex: widget.navigationShell.currentIndex,
        onTap: (index) => widget.navigationShell.goBranch(index),
        centerAction: AppBottomNavCenterAction(
          iconAsset: AppNavigationIcons.centerAction,
          semanticLabel: 'nav.create'.tr(),
          onTap: () {
            // Handle center action
          },
        ),
        items: [
          AppBottomNavItem(
            iconAsset: AppNavigationIcons.home,
            label: 'nav.home'.tr(),
          ),
          AppBottomNavItem(
            iconAsset: AppNavigationIcons.service,
            label: 'nav.requests'.tr(),
          ),
          AppBottomNavItem(
            iconAsset: AppNavigationIcons.messages,
            label: 'nav.messages'.tr(),
          ),
          AppBottomNavItem(
            iconAsset: AppNavigationIcons.settings,
            label: 'nav.settings'.tr(),
          ),
          AppBottomNavItem(
            iconAsset: AppNavigationIcons.home,
            label: 'nav.more'.tr(),
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
| `controller` | `NotchBottomBarController` | Controller for notch animation — must be initialized with `index: 2` |
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

The implementation uses every available feature from `animated_notch_bottom_bar`:

- ✅ `notchBottomBarController` — for notch position control
- ✅ `bottomBarItems` — list of `BottomBarItem` configurations
- ✅ `onTap` — tap callback
- ✅ `color` — background color
- ✅ `notchColor` — notch fill color
- ✅ `durationInMilliSeconds` — animation duration
- ✅ `bottomBarHeight` — bar height
- ✅ `kBottomRadius` — notch bottom radius
- ✅ `showTopRadius` — show bar top rounded corners
- ✅ `showBottomRadius` — show bar bottom rounded corners
- ✅ `removeMargins` — remove default margins
- ✅ `elevation` — Material elevation
- ✅ `shadowElevation` — shadow depth
- ✅ `showShadow` — enable/disable shadow
- ✅ `showBlurBottomBar` — background blur effect
- ✅ `blurOpacity`, `blurFilterX`, `blurFilterY` — blur parameters
- ✅ `kIconSize` — icon size
- ✅ `topMargin` — top spacing
- ✅ `circleMargin` — notch circle margin
- ✅ `showLabel` — display labels
- ✅ `itemLabelWidget` — custom label widgets

## Design Tokens

All styling is controlled via `BottomNavTokens`:

### Layout Tokens
- `bottomBarHeight: 72.0` — bar height
- `kBottomRadius: 28.0` — notch corner radius
- `kIconSize: 24.0` — icon size
- `topMargin: 12.0` — top spacing
- `circleMargin: 8.0` — notch circle margin
- `centerFabSize: 52.0` — center button size

### Color Tokens
- `backgroundColor()` — bar background (theme-dependent)
- `selectedIconColor()` — selected item color
- `unselectedIconColor()` — unselected item color
- `disabledIconColor()` — disabled item color
- `centerFabActiveColor()` — active FAB color
- `centerFabInactiveColor()` — inactive FAB color

### Animation Tokens
- `durationInMilliSeconds: 450` — from `AppDurations.notchBar`
- `selectedIconScale: 1.1` — scale factor for selected icons
- `unselectedIconOpacity: 0.72` — opacity for unselected items
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
- Controller locking
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

**New API (5 items, no `leadingCount`)**:
```dart
AppBottomNavBar(
  controller: NotchBottomBarController(index: 2),  // ✅ Always index 2
  items: [item1, item2, item3, item4, item5],  // ✅ Exactly 5 items
  // ...
)
```

Key changes:
- **5 items required** — no longer configurable count
- **No `leadingCount`** — center is always at index 2
- **No `textDirection` override** — uses ambient `Directionality`
- **Simpler API** — removed internal slot mapping complexity

## Package Limitations

Current limitations of `animated_notch_bottom_bar` that cannot be customized:

1. **Fixed notch shape** — circular notch only; cannot use custom shapes
2. **Linear interpolation** — package uses linear animation; Figma uses custom easing
3. **Icon-label gap** — fixed at 5dp (Figma uses 4dp)
4. **Bar positioning** — requires manual padding adjustment to match Figma exactly

All other aspects match the Figma design via proper token configuration.

## References

- Package: https://pub.dev/packages/animated_notch_bottom_bar
- Figma: `Nab-Bar` (`3148:27106`)
- Icons: `packages/app_assets/lib/src/app_navigation_icons.dart`
- Tokens: `packages/design_system/lib/src/theme/tokens/bottom_nav_tokens.dart`
