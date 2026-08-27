# app_animations

Centralized animation design system for the Sanad monorepo. This is the
**only** package allowed to declare `flutter_animate`, `animations`, or
`lottie` (enforced by `dep_rules.yaml` + `scan_imports.dart`) — every other
package consumes animation through this package's API.

Tier 0 (see `dep_rules.yaml`) — depends only on `core`, `app_assets`, and
Flutter, so any package (including `design_system`) can depend on it.

## Motion tokens

```dart
import 'package:app_animations/app_animations.dart';

AnimatedContainer(
  duration: AppMotionDuration.normal,
  curve: AppMotionCurve.standard,
  ...
)
```

`AppMotionDuration`: `instant`, `fast` (150ms), `quick` (200ms), `normal`
(300ms), `emphasis` (500ms), `pageTransition` (350ms), `shimmer` (1200ms).

`AppMotionCurve`: `standard` (easeInOut), `decelerated` (easeOut),
`accelerated` (easeIn), `emphasizedDecelerate` (easeOutCubic),
`emphasizedAccelerate` (easeInCubic).

Do not add a new value to either token class for a one-off duration/curve
used in exactly one place — define it as a local constant next to the
widget that needs it instead, and only promote it here once a second,
genuinely-similar use case appears.

## Reduced motion

```dart
if (AppMotion.reduceMotionOf(context)) { /* suppress decorative motion */ }
```

Wraps `MediaQuery.disableAnimations` (OS reduce-motion) and
`MediaQuery.accessibleNavigation` (screen reader active). Every effect,
pattern, and `AppLottie` (for `isDecorative: true` assets) already consult
this — you only need it directly when writing new bespoke motion.

**Policy:** decorative/ambient motion (illustrations, entrance flourishes,
staggered lists, button press feedback, shimmer sweeps) is suppressed or
shortened. Functional motion that communicates a state change (a loading
spinner, a page navigating, a sheet opening, a menu expanding) is never
suppressed — matching platform convention that essential motion survives
reduce-motion while decoration doesn't.

## Effects & patterns

```dart
myWidget.appFadeIn(context)
myWidget.appFadeSlideUp(context)      // opacity-only under reduced motion
myWidget.appFadeScale(context)
myWidget.appScaleIn(context)

AppPageEntrance(child: myPageBody)
AppListEntrance(index: i, child: myRow)   // bounded, staggered, runs ONCE
AppButtonFeedback(onTap: ..., child: myTappable)
AppStateTransition(value: status, builder: (context, status) => ...)
```

Apply effects to the smallest widget that needs to move — never wrap a
whole page or a large subtree implicitly.

**No generic shimmer effect is exposed here.** `design_system`'s
`AppShimmer` — the only shimmer usage in the app — is a documented
exception: it needs `ShaderMask` + `BlendMode.srcATop` to *replace* the
child's color with the traveling gradient, which `flutter_animate`'s
built-in shimmer effect (an overlay, not a replacement) can't reproduce
without a visible regression. It still sources its duration from
`AppMotionDuration.shimmer` and its reduced-motion behavior from
`AppMotion.reduceMotionOf`. If a second, genuinely generic shimmer need
appears, add a shared effect here then — don't add another bespoke copy.

## Lottie

```dart
AppLottie.loading()              // functional — never frozen by reduced motion
AppLottie.documentExtraction()   // functional
AppLottie.notFound(size: 160)    // decorative — frozen under reduced motion
AppLottie.forbidden(size: 160)   // decorative
```

No feature or design-system code should `import 'package:lottie/lottie.dart'`
directly — always go through `AppLottie`. Every asset renders inside a
`RepaintBoundary` + `Semantics(excludeSemantics: true)`, with `repeat`
explicit (never left to the package default).

Adding a new Lottie animation: add the asset under
`packages/app_assets/assets/animations/production/`, add a path constant to
`AppAnimations` (`package:app_assets`), then add a member to
[`AppLottieAsset`](lib/src/lottie/app_lottie_asset.dart) pointing at it.

## Page transitions

`AppPageTransitions.theme` is wired into `AppTheme.light()`/`.dark()`
(`design_system`) via `ThemeData.pageTransitionsTheme` — every
`MaterialPage` route (every `GoRoute.builder` route in both apps) picks it
up automatically. No per-route wiring needed. `ModalSheetRoute`
(`sheet_navigation`) is a `PopupRoute`, not a `MaterialPage`, so it is
unaffected — sheets keep their own `SheetTransitions`.

## Performance rules

- Keep animated subtrees small — wrap the widget that moves, not its
  ancestors. Prefer `AnimatedBuilder`/`ListenableBuilder`/
  `CustomPainter.repaint` scoping over rebuilding a large tree per tick.
- Never create an `AnimationController` inside `build()` — only in
  `initState`, and always `dispose()` it.
- Don't animate off-screen/inactive-route/behind-modal widgets — rely on
  `TickerMode` (automatic when a route/tab is inactive) rather than
  hand-rolled visibility checks.
- Avoid unbounded infinite loops; when one is genuinely needed (a loading
  spinner, a shimmer sweep), that is the sanctioned exception, not the norm.
- `AppListEntrance` never animates more than `maxAnimatedIndex` items and
  never replays after its first appearance — verify a new list usage
  doesn't defeat that (e.g. don't give it a `key` that changes every
  rebuild).
- Lottie assets in this app are small (all `< 25 KB`); if a future asset is
  significantly larger, downscale/re-export it rather than shipping it as-is.

## Documented exceptions (bespoke controllers kept outside this package)

Every custom `AnimationController` in the monorepo was reviewed. These are
kept as their own hand-rolled implementation — each still consumes
`AppMotionDuration`/`AppMotionCurve`/`AppMotion.reduceMotionOf` where
technically applicable — for the reason stated:

| Widget | Reason kept bespoke |
|---|---|
| `design_system`'s `AppShimmer` | `ShaderMask`/`BlendMode.srcATop` *replaces* pixel color with a traveling gradient; `flutter_animate`'s shimmer effect overlays instead — swapping would visibly regress every skeleton screen. See "Effects & patterns" above. |
| `design_system`'s `AppOtpField` caret | Auth-critical; a blinking-cursor `AnimationController` with `repeat(reverse: true)` is already minimal and correct — no generic effect models a caret blink, and tests already rely on its specific bounded-pump behavior. |
| `shared_ui`'s `AppEnhanceWithAiButton` | A `CustomPainter`-driven continuous conic-gradient rotation — no effect here animates a shader angle, only widget properties (opacity/translate/scale). Already exemplary on the performance rules (RepaintBoundary, TickerMode-aware, reduced-motion gated). |
| `bottom_nav_bar`'s `CircularMenu` | Vendored wholesale from an open-source package, not authored in-house (upstream code style/typos preserved) — left unmodified so future updates can diff cleanly; its own curve/duration defaults are dead code since the only call site (`BottomNavExpandableCenter`) always overrides them with `AppMotionCurve`/`BottomNavThemeData` values. |
| `sheet_navigation`'s sheet drag/morph (`ModalSheetRoute`, `SheetDragController`) | A `PopupRoute`'s own `AnimationController` driving a drag-coupled, app-wide nested-sheet morph — its curves/durations already source from `SheetTransitions`, itself built on `AppMotionCurve`/`AppMotionDuration` (see that class's own doc for the one deliberately bespoke value, `exitDuration`). |

## Diagnostics

`AnimationDebug.verboseRebuildLogging = true` (debug builds only) plus
`AnimationDebug.logRebuild('label')` calls in a suspect `build()` method —
use to confirm an animation isn't driving more rebuilds than intended.
