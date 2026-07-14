# Maps Platform — Full Architecture & Business Logic Audit

**Scope:** `packages/maps` + `packages/features/branches` (Coverage Area flow)
**Type:** Business + Architecture + UX + Performance + Clean Code audit
**Mode:** Findings only. No code was changed to produce this document.
**Verdict up front:** The user's suspicion is **correct**. The implementation is significantly more complex than the business it serves, and — more seriously — it does **not** implement the core business requirement (automatic nearby-area calculation) at all.

---

## Executive Summary

The Coverage Area feature is a one-screen interaction: pick a point, drag a radius, get auto-suggested areas, remove some, add one, confirm. The current platform models this with **2 BLoCs, 4 controllers, 3 parallel map-picker UIs, 14 widgets, 7 use cases, 3 Places providers, a view model, and a bottom sheet** — and still misses the single most important rule (auto-calculated areas).

The drift has three root causes:

1. **Premature genericization.** `maps` was built as a "platform" (followers, overlay controllers, polygon/polyline builders, three place providers) before a second consumer existed. Most of that surface is unused.
2. **Two overlapping BLoCs on one screen.** `CoverageAreaBloc` and `LocationPickerBloc` both own current-location + reverse-geocode + forward-geocode + camera-source state. The Coverage page now runs both and bridges them with a listener — doubling the geocoding pipeline.
3. **Requirement inversion.** The feature was built around *manual* area search (a bottom sheet) instead of the required *automatic* area calculation. The auto-calc use case exists but is dead code.

### Score Card

| Dimension | Score | One-line justification |
|---|---|---|
| **Overall Architecture** | **4.5 / 10** | Clean layering exists, but responsibilities are duplicated and the core requirement is unimplemented. |
| Business Logic | **3 / 10** | Auto nearby-areas missing; "add ONE area" unbounded; "tap/drag marker" not implemented. |
| UX | **5 / 10** | Search now on-page (good), but area-add is buried in a bottom sheet the business never asked for. |
| Performance | **4 / 10** | Two blocs → duplicate GPS + duplicate reverse-geocode on startup; triple radius state. |
| Clean Architecture | **6 / 10** | Layers are respected mostly; leaks: JSON parsing in a domain entity, dead use case, bypassed abstractions. |
| Maintainability | **4.5 / 10** | Two sources of truth for position/address/radius; parallel dead UIs invite drift. |
| Simplicity | **3 / 10** | Moving parts vastly exceed the problem. |
| Reusability | **5 / 10** | Genuinely reusable primitives exist, but reuse was designed speculatively, not from need. |
| Testability | **6.5 / 10** | BLoCs are testable and tested; controllers are testable; UI orchestration (two-bloc bridge) is not covered. |

---

## 1. Business Logic Audit

**Required flow:** open → map → move marker (tap / drag marker / search) → radius slider moves circle → **system auto-calculates nearby areas** → areas shown as chips → remove any → **add ONE extra** → confirm.

| Requirement | Status | Evidence |
|---|---|---|
| Google Map appears | ✅ Implemented | `CoverageAreaPage._buildMap` |
| Move marker by **searching** | ✅ Implemented | on-page `PlaceSearchBar` → `LocationPickerBloc` → bridges to `CoverageAreaLocationUpdated` |
| Move marker by **dragging the map** (pin fixed at center) | ⚠️ Reinterpreted | `onCameraIdle` → center → `CoverageAreaCameraIdle`. The pin never moves; the map moves under it. |
| Move marker by **tapping the map** | ❌ Missing | Coverage map has **no `onTap`** handler. Tapping does nothing. |
| Move marker by **dragging the marker** | ❌ Missing | The pin is an `IgnorePointer` SVG overlay, not a draggable `Marker`. |
| Radius slider changes circle | ✅ Implemented | `AppSlider` → `MapRadiusController.buildCircles` |
| **System auto-calculates nearby areas** | ❌ **NOT IMPLEMENTED** | `GetNearbyAreasUseCase` exists and is DI-registered but **called by nothing**. Verified: only self/plumbing references. |
| Areas appear as chips | ⚠️ Partial | Chips render, but only from **manually** added areas, never auto-calculated ones. |
| Remove any area | ✅ Implemented | `CoverageAreaServingAreaRemoved` |
| **Add ONE extra area** | ❌ Violated | The add-sheet lets the user add **unlimited** areas; the "one" constraint is not enforced anywhere. |
| Confirm | ✅ Implemented | `CoverageAreaResult` popped back |

**Unnecessary flows:** the entire serving-area *search* apparatus (search sheet + Places autocomplete for areas + prediction→ServingArea mapping) exists to do manually what the business said should be **automatic**.

**Missing flows:** auto nearby-area calculation on `(center, radius)` change; enforcement of the single-extra-area rule; tap-to-move and drag-marker interactions.

**Broken/dead flows:** `GetNearbyAreasUseCase` → `GeocodingRepository.nearbyAreaNames` is a fully wired vertical slice with **no caller** — dead business logic.

**Severity: P0.** The feature ships without its defining behavior.

---

## 2. UX Audit

| Expected | Current | Issue |
|---|---|---|
| Search on the Coverage page | ✅ Present | (Fixed recently — good.) |
| Areas appear automatically | ❌ | User must open a sheet and search to get any area at all. |
| Add one area inline | ❌ | "Add" opens a **modal bottom sheet** with its own search + its own confirm button. |
| Minimal navigation | ⚠️ | Extra layer: Page → Bottom Sheet → search → tap prediction → (sheet stays open) → Done. |
| Single confirm | ❌ | Two confirms: the sheet's "Done" and the page's "Confirm Coverage". |
| Consistent marker interaction | ❌ | Search moves the map; tapping does nothing; the "marker" can't be grabbed. Users will try to tap/drag the pin and nothing happens. |

**Lost context:** opening the add-area sheet spins up a *second* `LocationPickerBloc` inside the sheet with its own geocoding, disconnected from the page's map — the sheet doesn't know where the map currently is.

**Severity: P1.** The journey has more steps and more confirmations than the business described.

---

## 3. Architecture Audit (responsibility placement)

| Unit | Verdict | Problem |
|---|---|---|
| `CoverageAreaBloc` | Misplaced scope | Owns location + geocode + forward-geocode + radius + serving list + camera dedup. Duplicates 3 use cases already in `LocationPickerBloc`. |
| `LocationPickerBloc` | Overloaded | Permissions + GPS + reverse geocode + forward geocode + autocomplete + place details + camera source = ~6 responsibilities. |
| Two blocs on one page | Wrong | The Coverage page instantiates **both** and bridges `LocationPicker.position → CoverageArea.LocationUpdated`. One screen, two geocoding brains. |
| `MapCameraController` | Bypassed | Rich, tested abstraction — but `CoverageAreaPage` ignores it and drives a raw `GoogleMapController` + `MapRadiusController` directly. Abstraction exists yet isn't used where it matters. |
| `MapRadiusController` | OK-ish | Sound circle math, but it holds a *third* copy of radius (see §9). |
| `ServingAreaController` | Correct but thin | Good SRP (list add/remove/dedup). Reasonable. |
| `ServingAreaViewModel` | Dead | Exported, never consumed. Premature presentation-mapping abstraction. |
| `MapLocationPicker` (534 lines) | Parallel UI | A *second* full map-picking screen with search + controls + confirm, unrelated to Coverage. |
| `CoverageAreaPicker` | Dead parallel UI | A *third* coverage UI inside `maps`, unused by `branches`. |
| `NearbyPlacesSheet` | Dead | Only used by the unused `CoverageAreaPicker`. |
| `MapCameraFollower` / `MapOverlayController` (polygons/polylines) | Speculative | No consumer in the coverage domain. |
| Repositories / Services / Providers | Reasonable | Clean provider abstraction — but 2 of 3 providers (`backend`, `osm`) are stubs. |

**Severity: P1** (P0 for the two-bloc bridge, because it is also a correctness/perf issue).

---

## 4. BLoC Responsibility Audit (SRP)

- **`LocationPickerBloc` — violates SRP.** It is a location resolver, a permission handler, *and* a Places-autocomplete engine. Autocomplete + prediction + place-details clearly belong in a dedicated search/prediction unit.
- **`CoverageAreaBloc` — violates SRP and duplicates.** Coverage's job is `center + radius → areas`. It should not re-own current-location and geocoding; those already live in `LocationPickerBloc`. It also should own the auto-area calculation it currently lacks.

**What should move out of the blocs:** autocomplete/prediction/place-details → a `SearchController`/`PredictionController`; radius value → a single `RadiusController`; the raw geocoding pipeline → one shared location resolver used by both features rather than copied into each bloc.

---

## 5. Controller Audit (missing / mis-scoped)

| Controller | State today | Should be |
|---|---|---|
| `ServingAreaController` | Exists ✅ | Keep. |
| `RadiusController` | **Missing** | Radius value lives in bloc **and** page `setState(_previewRadiusKm)` **and** `MapRadiusController`. Consolidate. |
| `SearchController` / `PredictionController` | **Missing** | Autocomplete + predictions live inside blocs. Extract. |
| `SelectionController` | **Missing** | "Which point is selected" is smeared across camera-source enums in both blocs. |
| `MapInteractionController` | **Missing** | Tap / drag / camera-idle handling is duplicated between `CoverageAreaPage` and `MapLocationPicker`. |
| `MapCameraController` | Exists but bypassed | Use it in Coverage or delete the duplication. |

---

## 6. Widget Audit (size / splitting)

| Widget | Lines | Verdict |
|---|---|---|
| `PlaceSearchBar` | ~245 | ✅ Recently split into `PlaceSearchField` + `PlaceSuggestionsOverlay` + `PredictionTile`. Good. |
| `MapLocationPicker` | **534** | Too large — search state, map state, address field, permission message, error message all in one file. |
| `CoverageAreaPage` | **~465** | Large — hosts two blocs, a listener bridge, and 4 private build methods. The two-bloc orchestration is the real smell, not just size. |
| `CoverageAreaPicker` | ~178 | Should not exist (dead parallel UI). |
| `PlaceSuggestionsOverlay` | ~130 | Fine. |

---

## 7. Duplicate Code Audit

- **Reverse geocode:** implemented in both `CoverageAreaBloc._applyLocation` and `LocationPickerBloc._reverseGeocode`. Both run on the Coverage screen.
- **Forward geocode (search submit):** duplicated in `CoverageAreaBloc._onSearchSubmitted` and `LocationPickerBloc._submitViaGeocode`.
- **Current location bootstrap:** both blocs call `GetCurrentLocationUseCase` on start.
- **Camera-source enums:** `CoverageAreaCameraSource {none, programmatic}` vs `LocationPickerCameraSource {none, programmatic, user}` — near-duplicate concept.
- **Camera-idle → center:** logic exists in `CoverageAreaPage._onCameraIdle` and `MapLocationPicker._onCameraIdle`.
- **Area/chip rendering:** `ServingAreaChips` and `NearbyPlacesSheet` are two renderers for the same concept.
- **Op-id cancellation pattern:** re-implemented in both blocs.

**Severity: P1.**

---

## 8. Clean Architecture Audit

- **Leaky domain:** `PlacePrediction.fromJson` parses Google's `structured_formatting` JSON **inside a domain entity**. Domain now knows a provider's wire format. Belongs in a data-layer DTO.
- **Dead vertical slice:** `GetNearbyAreasUseCase` (domain) → `nearbyAreaNames` (repo/service) is fully built but unused — a layer maintained for nothing.
- **Bypassed abstraction:** `CoverageAreaPage` reaches for the raw `GoogleMapController` instead of `MapCameraController`, so the abstraction's guarantees (animation flags, position notifier) don't apply on the most important screen.
- **Presentation knows too much:** the page manually bridges two blocs and owns preview-radius state — orchestration that should be inside a bloc/controller.
- **Speculative public API:** `maps.dart` barrel exports 90+ symbols including followers, overlay CRUD, polygon/polyline builders that no consumer uses.

---

## 9. Performance Audit

- **Duplicate startup work (P0-ish):** on open, both `CoverageAreaBloc` and `LocationPickerBloc` receive a `Started` event. If no initial position is passed, **both** call GPS **and** both reverse-geocode — two location fixes + two geocode round-trips for one screen.
- **Triple radius state:** `_previewRadiusKm` (setState) + `state.radiusKm` (bloc) + `MapRadiusController.radiusKm`. Slider drags rebuild the page via `setState` while also feeding the controller.
- **Second bloc in the add-sheet:** opening "Add area" constructs another `LocationPickerBloc` (more use-case wiring, another potential geocode).
- **Bridge listener rebuild:** `MultiBlocListener` + `BlocConsumer` + nested `BlocBuilder`/`BlocSelector` create several rebuild paths for one map.
- **Unused animations/listeners:** `MapCameraFollower` stream plumbing and `MapOverlayController` notifiers are compiled/exported but idle.
- **Cache:** `GeocodingCache` (LRU) is good — but duplicated geocode calls partly defeat it because the two blocs may query different coordinates in the same gesture.

---

## 10. Simplicity Audit — "Would I build it this way?"

**No.** The business is a single screen with one map, one radius, an auto-list, and two edit actions. The current build has two blocs, four controllers (one bypassed, one dead-ish), three map-picker UIs, a view model nobody uses, a bottom sheet the spec never mentioned, and a Places stack (three providers) — while the one behavior that defines the feature (auto areas) is missing. Complexity is inversely correlated with the requirement.

---

## 11. Package Design Audit

- **Over-generic too early.** `maps` became a "platform" (followers, overlays, polygons, polylines, multi-provider Places) with exactly one real consumer (`branches`). Genericity was designed, not discovered.
- **APIs nobody needs:** `MapCameraFollower`, `MapOverlayController` polygon/polyline builders, `CoverageAreaPicker`, `NearbyPlacesSheet`, `ServingAreaViewModel`, `BackendPlacesProvider`/`OsmPlacesProvider` stubs.
- **What should disappear (candidates):** the dead parallel UIs and view model, the unused controllers, and one of the two blocs' overlapping responsibilities.

---

## 12. Business Objects Audit

| Object | Verdict |
|---|---|
| `ServingArea` entity | Keep. |
| `PlacePrediction` entity | Keep, but move `fromJson` to a DTO. |
| `ServingAreaViewModel` | Remove (unused). |
| `CoverageAreaState.cameraSource` + `LocationPickerCameraSource` | Collapse to one concept. |
| `CoverageAreaEvent` set | Reasonable after recent cleanup. |
| `LocationPickerEvent` set | Split search/prediction events out. |
| `MapEvent` sealed hierarchy (8 variants) | Mostly unused by coverage — verify consumers before keeping. |

---

## 13. Feature Flow Audit (transitions)

- **Coverage flow** and **LocationPicker flow** overlap ~70% (both resolve location + address). They should share one resolver, not two blocs.
- **ServingArea flow** is inverted: manual search instead of auto-calc.
- **Places / autocomplete / prediction flow** is justified only for the *main location search*; its reuse for *area adding* is the unnecessary transition.
- **Camera flow** exists twice (page + picker).
- **Unnecessary transitions:** Page → add-sheet → (new bloc) → search → select → Done → back to page.

---

## 14. Complexity Audit

| Metric | Reading |
|---|---|
| BLoCs for one screen | 2 (should be 1 + controllers) |
| Controllers | 4 (`ServingArea`, `MapCamera`, `MapRadius`, `MapCameraFollower`) — 1 dead, 1 bypassed |
| Sources of truth for radius | 3 |
| Sources of truth for position/address | 2 (both blocs) |
| Map-picker UIs in the platform | 3 (`CoverageAreaPage`, `CoverageAreaPicker`, `MapLocationPicker`) |
| Place providers | 3 (2 stubs) |
| Largest widget file | 534 lines |
| Dead vertical slices | 1 (`GetNearbyAreas…`) |

**Justified?** No — the moving-part count is not explained by the requirement; it is explained by speculative platform-building.

---

## 15. Refactor Cost (if kept as-is)

- **6 months:** the two-bloc bridge becomes load-bearing; any new field must be synced in two states. Duplicate geocode bugs get "fixed" with more guards. The missing auto-area feature gets bolted onto the manual sheet, entrenching the inversion.
- **1 year:** a second consumer of `maps` arrives and copies `MapLocationPicker`, creating a 4th picker. `ServingAreaViewModel`/dead controllers get "adopted" by someone who assumes they're intentional.
- **2 years:** removing any "platform" API is now risky (unknown consumers). Radius/position triple-state causes subtle desyncs on slow devices. Onboarding cost is high because the code contradicts the requirement doc.

---

## If I were designing this feature today

**One screen, one BLoC, thin controllers, no bottom sheet.**

```
CoverageAreaBloc  (the ONLY bloc for this screen)
  state: center, address, radiusKm, autoAreas[], extraArea?, status
  events:
    Started(initialPosition?)
    MapMoved(center)        // from tap, drag-marker, OR camera-idle — one entry point
    RadiusChanged(km)       // debounced
    SearchLocationPicked(latLng)   // from the on-page search
    AreaRemoved(id)
    ExtraAreaAdded(area)    // enforce max 1
    Confirmed
  on MapMoved / RadiusChanged / SearchLocationPicked:
       reverseGeocode(center)  → address
       getNearbyAreas(center, radiusKm) → autoAreas   // THE missing requirement
```

- **Location resolution** (GPS, reverse/forward geocode) lives in **one** injected `LocationResolver` service used by the bloc — not duplicated across two blocs.
- **Search** is a small `SearchController` (or a cubit) that only emits `PlacePrediction`s; selecting one dispatches `SearchLocationPicked`. No place-details detour needed if geocoding returns the point.
- **Radius** has exactly one owner (the bloc); the map circle is a pure render of `state.radiusKm`. Kill `_previewRadiusKm` (debounce in the bloc instead).
- **Marker interaction** is unified: tap, drag-marker, and camera-idle all funnel into `MapMoved(center)`. Implement tap + a real draggable `Marker` to satisfy the spec, or explicitly drop them from the requirement — but don't silently omit them.
- **Areas** are **auto-calculated** via `GetNearbyAreasUseCase` on every center/radius change (debounced), rendered as removable chips. "Add" is a single inline chip/field that appends **one** extra area — no modal, no second bloc, no second confirm.
- **Delete from the platform:** `CoverageAreaPicker`, `NearbyPlacesSheet`, `ServingAreaViewModel`, `MapCameraFollower`, and the `backend`/`osm` provider stubs until a real consumer exists. Keep `MapCameraController`, `MapRadiusController`, `ServingAreaController`, `AppGoogleMap`, and the split `PlaceSearchBar`.
- **Fix the leak:** move `PlacePrediction.fromJson` into a data DTO.

**Net:** 1 bloc, 2–3 small controllers, 1 resolver service, ~6 widgets, 0 bottom sheets, 1 confirm — and it actually calculates nearby areas.

---

## Priority Index

### Critical (P0)
1. **Auto nearby-area calculation is not implemented** — `GetNearbyAreasUseCase` is dead. This is the feature's core value. (§1, §8)
2. **Two BLoCs own the same location/geocode responsibilities on one screen** → duplicate GPS + reverse-geocode at startup; correctness + perf risk. (§3, §7, §9)

### High (P1)
3. **"Add ONE extra area" is unbounded** — no max enforced. (§1)
4. **Marker interaction incomplete** — no tap-to-move, no draggable marker; only map-drag + search. (§1, §2)
5. **Add-area is a modal bottom sheet with its own bloc + its own confirm** — flow the spec never asked for. (§2, §13)
6. **Triple radius state / double position state.** (§9)
7. **Duplicated geocode/forward/current-location/op-id logic across blocs.** (§7)

### Medium (P2)
8. **`MapCameraController` bypassed** on the main screen. (§3)
9. **Dead/parallel UIs:** `CoverageAreaPicker`, `NearbyPlacesSheet`, `MapLocationPicker` overlap. (§3, §6)
10. **`ServingAreaViewModel` and `MapCameraFollower` unused.** (§11, §12)
11. **`PlacePrediction.fromJson` leaks provider JSON into domain.** (§8)

### Low (P3)
12. **`MapLocationPicker` at 534 lines** should be split. (§6)
13. **Two near-identical camera-source enums.** (§7)
14. **`backend`/`osm` Places providers are stubs** exported as public API. (§11)
15. **`maps.dart` barrel exports 90+ speculative symbols.** (§11)

---

*End of audit. No files were modified other than the creation of this report.*
