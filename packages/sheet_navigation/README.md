# sheet_navigation

Reusable bottom-sheet navigation infrastructure. A custom `PopupRoute`
(`ModalSheetRoute`) that makes nested sheets behave like LinkedIn: pushing a
second sheet on top of a first one **morphs the first sheet to fullscreen**
while the new sheet slides up on top of it. Popping reverses the morph.

This package is infrastructure, not a feature. No feature package owns it;
every feature consumes it the same way.

## Why this exists

Before this package, every sheet in the app was a `showModalBottomSheet` (or
a `showApp*Sheet` wrapper around one) — a one-off overlay with no relationship
to its caller or to any other sheet. There was no way to push a second sheet
"on top of" a first one and have it feel like a connected navigation stack.
`ModalSheetRoute` is a real route on the root `Navigator`, so nested pushes
get real back-button/swipe-back/Hero/focus-traversal behavior for free.

## Architecture

```
lib/
  sheet_navigation.dart              barrel
  src/
    route/
      modal_sheet_route.dart         ModalSheetRoute<T> extends PopupRoute<T>
      sheet_route_settings.dart      SheetRouteSettings (config value object)
      sheet_transitions.dart         shared curves/durations
    gesture/
      sheet_drag_controller.dart     drag-to-dismiss / snap-to-extent math
    presentation/
      sheet_navigator.dart           SheetNavigator facade + showSheet()
      widgets/
        sheet_scaffold.dart          drag handle, title, safe-area, padding
        sheet_snap.dart              snap-extent helper
```

No `data/` layer — this package does no I/O. No Bloc — state lives in the
route's own `AnimationController` (enter/exit) and the drag gesture math
(`SheetDragController`), not in application state.

## Public API

```dart
abstract final class SheetNavigator {
  static Future<T?> push<T>(BuildContext context, Widget child, {SheetRouteSettings settings});
  static Future<T?> replace<T>(BuildContext context, Widget child, {SheetRouteSettings settings});
  static void pop<T extends Object?>(BuildContext context, [T? result]);
  static bool canPop(BuildContext context);
}

Future<T?> showSheet<T>(BuildContext context, {required Widget child, SheetRouteSettings settings});

enum SheetSize {
  content,   // wraps content, clamped to [minHeight, maxHeightFactor] — the default
  expanded,  // fills initialHeightFraction (or the largest snapFractions entry)
}

class SheetRouteSettings {
  const SheetRouteSettings({
    SheetSize sheetSize = SheetSize.content,
    double? initialHeightFraction,       // expanded only — null = largest snapFractions entry
    List<double> snapFractions = const [0.92],
    double? minHeight,                   // content only — floor in logical pixels
    double maxHeightFactor = 0.92,       // content only — ceiling as a fraction of screen height
    bool isDismissible = true,           // barrier tap dismisses
    bool enableDrag = true,              // drag-to-dismiss/snap + shows the drag handle
    bool expandPreviousToFullscreen = true, // the LinkedIn morph
    Color? barrierColor,                 // defaults to OverlayTokens.scrimColor()
    bool useSafeArea = true,
    String? restorationId,
    String? title,                       // optional title row next to the handle
    bool padChild = true,                // horizontal padding around child
  });
}
```

### Sizing (`SheetSize`)

Every sheet now picks one of two sizing behaviors, set on the **route**
(`SheetRouteSettings.sheetSize`), not on individual widgets — the same
`SheetScaffold` powers both, so there's nothing to duplicate:

- **`SheetSize.content`** (the default) — the sheet wraps its content. A
  3-row action menu renders as a 3-row-tall sheet, not a near-fullscreen
  sheet with empty space below it. Bounded by `minHeight` (floor, so tiny
  content doesn't render as a barely-there card) and `maxHeightFactor`
  (ceiling, as a fraction of the screen — content taller than this should be
  wrapped in a scrollable by the caller, same as today).
- **`SheetSize.expanded`** — the sheet fills `initialHeightFraction` (or the
  largest `snapFractions` entry) regardless of content size. Use for long
  forms: OTP, search, multi-step flows, large settings pages.

Both modes still morph to fullscreen when a child sheet is pushed on top —
the morph animates the height bounds toward the full screen height in either
case, so a small content-sized menu becomes a fullscreen backdrop exactly
like an expanded one does.

```dart
// A short menu — sizes to its 3 rows, no wasted space.
await SheetNavigator.push<void>(context, const ActionMenu());

// The same menu, but never smaller than 220px even if it somehow renders
// with only one row.
await SheetNavigator.push<void>(
  context,
  const ActionMenu(),
  settings: const SheetRouteSettings(minHeight: 220),
);

// A long form that should always take up (up to) 92% of the screen.
await SheetNavigator.push<void>(
  context,
  const SearchSheet(),
  settings: const SheetRouteSettings(sheetSize: SheetSize.expanded),
);
```

Everything else (`ModalSheetRoute`, `SheetScaffold`, `SheetDragController`,
`SheetSnap`, `SheetTransitions`) is exported for advanced use (building a
custom presentation helper) but `SheetNavigator`/`showSheet` is the only API
most call sites need.

## Basic usage

```dart
final result = await SheetNavigator.push<String>(
  context,
  const MyPickerSheet(),
);
```

That's it — no `BuildContext`-holding route object to construct, no
`showModalBottomSheet` boilerplate.

### With options

```dart
await SheetNavigator.push<void>(
  context,
  const MenuBody(),
  settings: const SheetRouteSettings(
    enableDrag: false,   // no drag handle, no drag-dismiss (e.g. a menu of rows)
    padChild: false,      // edge-to-edge content
  ),
);
```

### Nested sheets (the LinkedIn behavior)

```dart
// From inside Sheet A:
final picked = await SheetNavigator.push<Thing>(context, const SheetB());
// Sheet A automatically morphed to fullscreen while Sheet B was on top,
// and un-morphs back to its resting size the moment Sheet B pops.
```

No special code is required to get the morph — it happens automatically
whenever a `ModalSheetRoute` is pushed while another `ModalSheetRoute` is
already the current route, as long as neither disabled it via
`expandPreviousToFullscreen: false`.

### Popping with a result

```dart
SheetNavigator.pop(context, myResult);
// or, equivalently, straight through Navigator:
Navigator.of(context).pop(myResult);
```

Dismissing via barrier tap, drag, or the hardware back button all resolve the
awaited `Future` with `null` (not an exception) — callers should treat `null`
as "cancelled", exactly like `showModalBottomSheet`.

## Route lifecycle

1. **Push** — `SheetNavigator.push` calls `Navigator.of(context, rootNavigator: true).push(ModalSheetRoute(...))`.
2. **Enter** — slide-up + barrier fade, driven by the route's own animation (`SheetTransitions.enterDuration`, `enterCurve`).
3. **Morph** (if a child `ModalSheetRoute` is pushed on top) — this route's `secondaryAnimation` drives height-factor growth toward 1.0 and top-corner-radius shrinkage toward 0, via `SheetTransitions.morphCurve`.
4. **Drag** — `SheetDragController` maps vertical drag delta directly onto the route's `AnimationController.value`; release resolves to dismiss (past a velocity/extent threshold) or an animated snap to the nearest `snapFractions` entry.
5. **Pop** — `Navigator.pop(result)` (or a dismiss gesture) completes the route's future with `result` (or `null`).
6. **Dispose** — the drag controller and animation are torn down by the route/Navigator; nothing to clean up manually.

## Migration guide (from `showModalBottomSheet` / `showApp*Sheet`)

`SheetNavigator` is now the **only** sheet-presentation mechanism in the app.
`showAppBottomSheet`, `showAppModalSheet`, `showAppActionSheet`, and
`showAppSelectSheet` have all been deleted — the design_system/shared_ui
widgets they used to wrap (`AppActionList` — formerly `AppActionSheet` —
and `AppSelectSheet`) are now chrome-free content, pushed directly:

| Old | New |
|---|---|
| `showModalBottomSheet<T>(context: context, builder: (_) => Body())` | `SheetNavigator.push<T>(context, const Body())` |
| `showAppBottomSheet<T>(context: context, child: Body())` | `SheetNavigator.push<T>(context, Body())` |
| `showAppBottomSheet<T>(context: context, title: 'X', child: Body())` | `SheetNavigator.push<T>(context, Body(), settings: SheetRouteSettings(title: 'X'))` |
| `showAppBottomSheet<T>(context: context, padChild: false, child: Body())` | `SheetNavigator.push<T>(context, Body(), settings: const SheetRouteSettings(padChild: false))` |
| `showAppModalSheet<T>(context: context, child: Body())` | `SheetNavigator.push<T>(context, Body(), settings: const SheetRouteSettings(sheetSize: SheetSize.expanded))` |
| `showAppActionSheet<T>(context: context, title: 'X', items: [...])` | `SheetNavigator.push<T>(context, AppActionList(items: [...]), settings: SheetRouteSettings(title: 'X', padChild: false))` |
| `showAppSelectSheet<T>(context: context, title: 'X', ...)` | `SheetNavigator.push<List<T>>(context, AppSelectSheet<T>(...), settings: SheetRouteSettings(title: 'X', padChild: false))` |

`AppActionList` and `AppSelectSheet` own no chrome of their own (no surface,
no drag handle, no barrier, no detached cancel row) — dismissal without a
selection is the sheet's barrier/drag, not a dedicated cancel row. If some
other piece of content still renders its own full chrome, pass
`settings: const SheetRouteSettings(enableDrag: false, padChild: false)` so
`SheetScaffold` doesn't draw a second handle/padding on top of it.

**On `sheetSize` when migrating:** `SheetSize.content` is the default for a
reason — most sheets genuinely are short menus/confirmations/pickers, and
`showModalBottomSheet`/`showAppBottomSheet` already sized to content in that
case. But every call site that existed *before* `SheetSize` was introduced
was migrated with an explicit `sheetSize: SheetSize.expanded` regardless of
whether it would look fine under content sizing, specifically so no existing
screen's rendered behavior changed. If you're touching one of those call
sites anyway, it's worth checking whether it can drop the explicit
`SheetSize.expanded` and use the (arguably better) content-sized default
instead — but that's a deliberate follow-up, not something this migration did
automatically.

**On the `permissions` tier:** `packages/permissions` now depends on
`sheet_navigation` directly. `sheet_navigation` was moved from tier 3 to
tier 2 specifically to unblock this — its own dependencies (`core`,
`design_system`, `shared_ui`, `go_router`) are all tier ≤ 1, so the move was
safe and every existing dependent stayed valid.

## Dos and don'ts

- **Do** use `SheetNavigator.push`/`showSheet` for anything that used to be a
  `showModalBottomSheet` or `showApp*Sheet` call. If the target package
  genuinely cannot depend on `sheet_navigation` (lower tier, e.g. `shared_ui`
  itself), inject the picker as a callback instead — see
  `AppAddScheduleDaySheet.onPickDay` in `shared_ui` for the pattern.
- **Do** pass `enableDrag: false` when your content already renders its own
  drag handle — otherwise you'll get two.
- **Do** reach for `SheetSize.expanded` for long forms (OTP, search, settings)
  and leave short sheets (menus, confirmations, single-field pickers) on the
  `SheetSize.content` default — don't build a second scaffold to get either.
- **Don't** construct `ModalSheetRoute` directly from feature code. Go through
  `SheetNavigator` so presentation stays consistent and testable.
- **Don't** assume `expandPreviousToFullscreen` guarantees pixel-exact layout
  for arbitrarily-tall content — it grows the sheet's height factor toward 1.0
  and lerps the corner radius; content that doesn't reflow well at fullscreen
  should size itself with `Expanded`/`SingleChildScrollView`, not fixed heights.
- **Don't** rely on `ModalSheetRoute` for anything that needs to be a real
  go_router-addressable location (deep link, browser back/forward on web) —
  it's pushed imperatively on the root `Navigator`, not declared as a route.

## Known limitations

- State restoration (`restorationId`) is accepted but only partially exercised
  by the current gesture/animation code — a multi-level nested sheet stack is
  not guaranteed to fully reconstruct after process death.
- No API distinguishes "hide the drag handle but still allow dismiss-by-drag"
  from "disable the drag gesture entirely" — both are controlled by the single
  `enableDrag` flag today.
- `SheetSize.content` content taller than `maxHeightFactor` relies on the
  caller wrapping it in a scrollable (`SingleChildScrollView`/`ListView`), same
  as it always has — the ceiling clamps the *sheet's* height, it does not make
  non-scrollable content scrollable for you.
