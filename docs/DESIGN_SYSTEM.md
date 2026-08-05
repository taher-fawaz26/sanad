# Design System

## Overview

The Sanad Design System (`packages/design_system`) provides theme, tokens, and reusable UI components. Design Tokens are the single source of truth.

## Package Boundaries

| Package | Contains |
|---------|----------|
| `app_assets` | Shared images, SVGs, icons, lottie/animations, and their path constants only — no widgets, no fonts (fonts stay in `design_system`) |
| `design_system` | Design tokens, primitive components (`lib/src/components/`), and higher-level domain-agnostic composed UI (`lib/src/shared_ui/`) |

`shared_widgets` was dissolved: primitive widgets (`AppSvgPicture`, `AppListCard`, `AppCloseIcon`, `AppNotificationIcon`) moved into `design_system/components/`; the OTP field moved into `packages/features/otp`; branch widgets moved into `packages/features/branches`. See the Component Ownership Policy and Architecture Decision Tree in `docs/ARCHITECTURE.md`.

Dev-only preview/showcase widgets (`AppColorPalettePreview`, `AppTypographyPreview`) live in `design_system/lib/src/dev/` and are intentionally **not** exported from any barrel — internal use only.

## Token System

### Colors

Consume via `context.appColors.*` — never `Colors.*` or hex literals.

Palettes: `MainPalette`, `AccentPalette`, `DarkPalette`, `SkyPalette`, `RedPalette`, `YellowPalette`
Semantic colors: `LightColors` / `DarkColors` → `AppColors` ThemeExtension

### Spacing

`AppSpacing` — Figma Guide `892:4898` (16px base), via `responsiveSpacing()`:

| Step | rem | dp | Token |
|------|-----|----|-------|
| 1 | 0.25rem | 4 | `xs` |
| 2 | 0.5rem | 8 | `sm` |
| 3 | 0.75rem | 12 | `md` |
| 4 | 1rem | 16 | `lg` |
| 5 | 1.25rem | 20 | `xl` |
| 6 | 1.5rem | 24 | `xxl` |
| 8 | 2rem | 32 | `xxxl` |
| 10 | 2.5rem | 40 | `xxxxl` |
| 12 | 3rem | 48 | `xxxxxl` |
| 16 | 4rem | 64 | `space64` |
| 20 | 5rem | 80 | `pageGap` / `space80` |
| 24 | 6rem | 96 | `space96` |
| 32 | 8rem | 128 | `space128` |
| 40 | 10rem | 160 | `space160` |
| 48 | 12rem | 192 | `space192` |
| 56 | 14rem | 224 | `space224` |
| 64 | 16rem | 256 | `space256` |

### Radius

`AppRadius` — sm, md, lg, xl, xxl

### Shadows

`AppShadows` — Figma Box Shadow guide `892:4898` (`#141414` ink):

| Token | Layers |
|-------|--------|
| `small` | `0 0 8px` @ 8% + `0 0 1px` @ 4% |
| `medium` | `0 1px 8px 2px` @ 8% + `0 0 1px` @ 8% |
| `large` | `0 1px 24px 8px` @ 8% + `0 0 1px` @ 8% |
| `none` | empty |
| `xs` | legacy micro (1px @ 4%) — prefer `small` for new UI |

### Dimensions

`AppDimension` — icon sizes, field heights, component dimensions

### Durations

`AppDurations` — animation and timer durations

## Components (40+)

Key components exported from `design_system.dart`:

- **Input:** `AppTextField`, `AppSelectField`, `AppPhoneField`, `AppSearchField`, `AppFieldAction`, `AppFieldLabel` — pass `isRequired: true` on text/phone/select fields for a red `*` after the label
- **Action:** `AppButton`, `AppButtonGroup`, `AppIconButton`
- **Navigation:** `AppNavBar`, `AppLargeNavBar`, `AppTabBar`

Provider shell navigation composes the `bottom_nav_bar` package in
`apps/sanad_provider/lib/src/routing/shell/main_shell.dart` — not in `design_system`.

- **Display:** `AppSection`, `AppSectionCard`, `AppSectionHeader`, `AppStatusBadge`, `AppChip`, `AppAvatar`, `AppKeyValueCard`
- **Feedback:** `AppSnackbar`, `AppProgressBar`, `AppPopover`
- **Form:** `AppCheckbox`, `AppRadio`, `AppRadioTile`, `AppSwitch`, `AppSlider`
- **Layout:** `AppDivider`, `AppWizardStepIndicator`, `AppStepper`
- **Overlays:** `AppBottomSheet`, `AppActionSheet`, `AppBackdrop` — see [Overlays](#overlays) below
- **Schedule:** `AppScheduleDayRow`, `AppAddScheduleDaySheet` (shell-agnostic day + from/to form; pair with `SheetNavigator`)
- **Empty states:** `AppEmptyState`, `AppNetworkFailureState`, `AppGenericEmptyState` — see [Empty States](#empty-states) below

## Empty States

Figma `empty states` (`321:8333`). All four components live in `design_system/lib/src/shared_ui/app_empty_state.dart` (higher-level composed UI, not a primitive).

| Component | Purpose | Illustration source |
|---|---|---|
| `AppEmptyState` | Generic centered illustration + title + description + optional action | Caller-provided |
| `AppEmptyStateImage` | Package-aware raster loader for state illustrations | `app_assets` or app-owned assets |
| `AppNetworkFailureState` | No internet connection preset (`321:8297`) | `AppImages.networkFailure` (`app_assets`) |
| `AppGenericEmptyState` | Generic empty preset (`328:9898`) | `AppImages.emptyState` (`app_assets`) |

Shared illustrations live in `packages/app_assets/assets/images/empty_states/` via `AppImages` (`package:app_assets/app_assets.dart`). App-specific illustrations (e.g. search, workers) stay in the host app's own `assets/` folder — see the Asset Ownership Policy in `docs/ARCHITECTURE.md`.

`EmptyStateTokens` — Figma spacing: `pt 32`, `pb 24`, `px 24`, section gap `24`, text gap `8`, content width `279`.

## Overlays

Figma `Views / Bottom Sheets` (`40:9140`), `Views / Action Sheets` (`40:9109`),
`Views / Backdrops` (`40:9149`), `Native / Bottom Sheet Indicator` (`40:8321`),
and `_Partials/Overlay` (`40:8737`).

### Which component to use

| Component | Scrim / barrier | Purpose |
|---|---|---|
| `AppBottomSheet` | **None** — sheet floats over the live screen | Contextual content / menus that keep the page visible behind them (`40:9140`) |
| `AppActionSheet` | Dark scrim (`_Partials/Overlay`) | Discrete action list + Cancel (`40:9109`) |
| `AppBackdrop` | Used as a stacked front/back sheet surface | Hint that another sheet sits behind the current one (`40:9149`) |

### Components

| Component | Purpose | Variants / States | Public API |
|---|---|---|---|
| `AppBottomSheet` | Sheet surface with optional drag handle, title, and body — **no dimming overlay** | Light/dark, with/without drag handle, with/without title, `padChild` for edge-to-edge rows | `AppBottomSheet({title, child, showDragHandle, padChild})`, `showAppBottomSheet(context: ..., title:, child:, isDismissible:, showDragHandle:, padChild:)` |
| `AppActionSheet` | List of tappable actions + separate Cancel row (with scrim) | Light/dark, destructive item, optional leading icon per item | `AppActionSheet({title, items, cancelLabel, onCancel})`, `AppActionSheetItem({label, onTap, leading, isDestructive})`, `showAppActionSheet(context: ..., items:, title:, cancelLabel:, onCancel:)` |
| `AppBackdrop` | Front sheet + back-sheet "peek" strip, hinting a stacked sheet behind it | Light/dark, with/without drag handle, with/without title | `AppBackdrop({child, title, showDragHandle})` |

All three share the internal `OverlayDragHandle` widget
(`lib/src/components/internal/overlay_drag_handle.dart`) for the native
drag-handle indicator (`Native / Bottom Sheet Indicator`, `40:8321`).

### Tokens — `OverlayTokens`

Native-chrome "Ink" / "Sky (chrome)" colors, distinct from the
`DarkPalette`/`SkyPalette` hue ramps used for semantic UI colors. Confirmed
from `_Partials/Overlay` (`40:8737`), `Native / Bottom Sheet Indicator`
(`40:8321`), `Views / Action Sheets` (`40:9109`), and
`Views / Bottom Sheets` (`40:9140`):

| Token | Hex | Figma name | Usage |
|---|---|---|---|
| `ink900` | `#090A0A` | Ink/Darkest | Scrim base (via `scrimColor()`) |
| `ink800` | `#202325` | Ink/Darker | Dark-mode sheet/action-sheet surface |
| `ink700` | `#303437` | Ink/Dark | Dark-mode action-sheet divider |
| `ink600` | `#6C7072` | Ink/Light | Dark-mode drag handle & cancel text |
| `chromeBase` | `#CDCFD0` | Sky/Base | Light-mode drag handle |
| `chromeLighter` | `#F2F4F5` | Sky/Lighter | Light-mode action-sheet divider |
| `chromeDark` | `#979C9E` | Sky/Dark | Light-mode cancel text |
| `scrimColor()` | `ink900 @ 70%` | — | Barrier behind `AppActionSheet` only — **not** `AppBottomSheet` |

`ActionSheetStyleSpec` additionally exposes `leadingIconSize` (24dp),
`itemHorizontalGap` (12dp), and `leadingLabelInset` (60dp) for the optional
leading-icon row layout (`24px` icon inset + `24px` icon + `12px` gap =
`60px` label inset, matching Figma exactly).

### Documented gaps

- **Ink scale coverage:** only 4 Ink steps (`ink900`–`ink600`) and 3 chrome
  steps are confirmed from the overlay components audited so far. Extend
  `OverlayTokens` (don't approximate with `DarkPalette`/`SkyPalette`) if a
  future component references additional steps.
- **`AppBackdrop` peek visual fidelity:** the back-sheet peek in
  `Views / Backdrops` (`40:9149`) is a flattened raster image in Figma, not
  a vector layer, so its exact fill/shadow cannot be extracted from tokens.
  The implementation reuses the front sheet's `surfaceColor`/`topRadius`
  (`BottomSheetStyleSpec.backdropPeekHeight` = 10dp,
  `backdropPeekHorizontalInset` = 16dp) — an explicitly allowed reuse, not
  an invented value.
- **`Native / Home Indicator`** (`40:9099`) is OS-level chrome shown only
  for Figma mockup framing — out of scope, not an app UI component.

## Adding a New Component

1. Create token file in `lib/src/theme/tokens/`
2. Create component in `lib/src/components/`
3. Export in `design_system.dart`
4. Update this document

## Theme

```dart
MaterialApp(theme: AppTheme.light(), darkTheme: AppTheme.dark())
```

Access colors: `context.appColors.primary`
Access typography: `context.appTypography.regularNormal`
