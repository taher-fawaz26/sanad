# Services Feature — Architecture & Code Quality Audit + Refactoring Plan

> **Deliverable:** Audit + implementation-ready plan. On approval, executed phase by phase.

---

## Context

The Services feature (`apps/sanad_provider/packages/services`) is the provider app's most
BLoC-heavy package (7 BLoCs): the provider's own services list, service requests list,
service details, add/edit service, request-new-service, catalog browse, and analytics. It
recently received a UI + skeleton refresh (commit `5747f58`).

**Key finding, verified across code + live Swagger:** Services already sits on the repo's
shared infrastructure — `PaginationMixin` (core), `SanadPagedList` (shared_ui, the single
`infinite_scroll_pagination` boundary), `AppSkeletonizer`/`AppSkeletonList`,
`AppRefreshIndicator`, `failureErrorDisplay`, the `Failure`/`TaskEither` (fpdart) error model,
DTO-extends-entity + `EntityConverter`, and — critically — **`MediaUploadBloc`**
(`packages/media_upload`), which already implements bounded-concurrency multi-file upload with
per-image state, retry, and failure isolation. Clean-architecture layering is strict and
consistent throughout.

Therefore this is a **conformance + hardening + small-gap-fill audit**, not a rewrite. Two
directives from the user shape the scope:

1. **Status filter → WIRE UP** the existing (dead) "My Services" Status dropdown to the
   already-working BLoC path (Active/Inactive via the existing `ProviderServiceStatus` enum;
   reset pagination on change; compose with search; survive refresh).
2. **Type filter → KEEP visible, intentionally unwired.** Backend has no `type` param
   (confirmed absent in Swagger). Do **not** delete it, do **not** fake local filtering, do
   **not** invent a query param. Leave the callback reserved for future backend support.

Plus a bug fix + gap: **multi-image upload.** The infra exists; the "only first image uploads"
symptom is a one-parameter picker bug. Edit-service currently ignores images entirely and
needs wiring to the image sub-resource endpoints.

The plan marks large swathes **KEEP — no change** to avoid over-refactoring.

---

## Current Architecture

**Package:** `apps/sanad_provider/packages/services`, wired into the provider bottom-nav shell
branch via `ServicesModule.shellRoute()`. Sibling `packages/features/services/` is an empty
stale stub — ignore.

### Data-flow (actual)

```
UI (ProviderServicesPage / *FormBody / *ImagesField)
  → Bloc (ServicesListBloc+PaginationMixin, ServiceActionBloc, Add/Edit/RequestNew, Analytics,
          MediaUploadBloc [shared, per-surface factory])
     ├─ list reads: loadFirstPage / loadNextPage / refresh / onQueryChanged (mixin owns reducer)
     ├─ mutations: usecase(...).run() → fold → emit
     └─ images: MediaUploadBloc → bounded-concurrent upload-single per asset → per-item mediaId
  → UseCase (17 thin delegators) → Repository (.map dto→entity) → RemoteDataSource
  → BaseApiClient (Dio + ErrorMapper→Failure + NetworkGuard) → HTTP (dev-api.trysanad.us)
  → JSON envelope {data:[...],meta:{...}} → DTO.fromJson → ServicesPagedResult<T>
  → repo maps → Page<Entity> → PaginationData<Entity> (state slice)
  → SanadPagedList (toPagingState adapter) → keyed rows
```

**Backend contract (verified vs live Swagger `dev-api.trysanad.us/api/docs-json`):**
- `GET /provider-services` — query `page, limit(≤100), search, status∈{active,inactive,all}`. **No `type` param.**
- `POST /provider-services` — `{serviceId(uuid), description(≤500, REQUIRED), imageIds(uuid[], minItems 1, maxItems 6)}`. `imageIds` = **media ids**; first becomes primary implicitly.
- `PATCH /provider-services/{id}` — `{description}` **only**; images NOT updatable here.
- `POST /provider-services/{id}/images` — `{mediaId}`; `DELETE …/images/{imageId}` and `PATCH …/images/{imageId}/primary` address by **image-row id** (not media id). All return the detail DTO.
- `POST /media/upload-single` — multipart field **`file`**; returns `{id (=media id), url, mimeType, size, …}`. Batch `POST /media/upload` exists but we intentionally **do not** use it.
- `POST /service-requests` — `{name, categoryId, description, imageIds(uuid[], maxItems 6, optional)}`.

**Concurrency contract:** `droppable()` = refresh, load-more, add/edit/action mutations.
`restartable()` = search + status change. `concurrent` (default) = initial fetch, list
fold-ins, analytics, **and request-new submit (defect — see B3)**.

---

## Architecture Findings

| ID | Sev | Area | Problem | Evidence | Recommendation |
|----|-----|------|---------|----------|----------------|
| A1 | P2 | Domain | 15/17 use cases are pure one-line delegators (no logic) | `usecases/*` | KEEP (repo convention) — see U1 |
| A2 | P2 | Data | `getOverview()` returns the DTO directly as the entity — only method skipping DTO→entity mapping | `provider_services_repository_impl.dart`; `provider_service_overview_dto.dart` has no `toEntity()` | Add `EntityConverter`+`toEntity()`; map in repo |
| A3 | P2 | Data | Image mutations asymmetric: `addImage` refetches full service; `setPrimaryImage`/`deleteImage` return the PATCH/DELETE detail response | `provider_services_repository_impl.dart` | Unify: all three return updated `ProviderServiceEntity` (all endpoints already return the detail DTO — just map consistently) |
| A4 | P3 | Domain | `all` enum sentinels in status entities | `provider_service_status.dart`, `service_request_status.dart` | KEEP — documented, needed for filter |
| A5 | P3 | Boundary | `easy_localization` + `localization` both declared | `pubspec.yaml` | Verify redundancy; drop direct dep if wrapped (D1) |

---

## BLoC Findings

| ID | Sev | Problem | Evidence | Recommendation |
|----|-----|---------|----------|----------------|
| **B1** | **P1** | **Cross-transformer stale-append race.** Load-more (`droppable()`) is not cancelled by a search/status change (`restartable()`) — different event types. Sequence: load-more(page2, queryA) in flight → user types → `onQueryChanged` resets to fresh `PaginationData(loading)` + fetches page 1 → the stale page-2 fetch resolves later; `_fetch` re-reads `state`, and with `append:true` does `_mergeDedup(current.items, staleItems)`, grafting old-query rows onto the new query and overwriting `meta` with stale page-2 meta. Same root corrupts refresh-vs-load-more. | `pagination_mixin.dart:61-71,94-128`; `services_list_bloc.dart:65-76,83-90` | **Fetch epoch in `PaginationMixin`:** `int _epoch`; bump in `loadFirstPage`/`refresh`/`onQueryChanged`; capture at `_fetch` start; drop the result if `epoch != _epoch` before emitting. Fixes `services`+`service_requests`+`workers` centrally. Add regression test. |
| **B3** | **P1** | `RequestNewServiceBloc._onSubmitted` has **no** transformer (add/edit/action all `droppable()`) → double-tap = duplicate `POST /service-requests`. | `request_new_service_bloc.dart:17` | Add `transformer: droppable()` |
| B2 | P2 | Initial `Fetch`→`loadFirstPage` has no transformer while `refresh` (same reducer) is `droppable()`. | `services_list_bloc.dart:60`; same in requests bloc | Add `droppable()` to `Fetch` for symmetry |
| B4 | P3 | `_onReplaced`/`_onRemoved` fold-ins (default concurrent) can be overwritten by a concurrent non-append refresh on resolve. Synchronous so safe today. | `services_list_bloc.dart:100-118`; `_fetch` non-append replaces wholesale | KEEP; the B1 epoch narrows it. Revisit only if it bites |
| B5 | P3 | Debounce is inline `Future.delayed(350ms)` not core `Debouncer`. Works via `restartable()`. | `services_list_bloc.dart:14,88`; `core/.../utils/debounce.dart` | KEEP or standardize (cosmetic) |
| B6 | P3 | Two `ServiceActionBloc` instances (list + details page). | `services_module.dart` | KEEP — intentional per-page scoping; document so nobody "dedupes" it |

---

## Use Case Findings

All 17 are thin delegators (class **C — small**), matching the repo convention (workers/branches
do the same). **U1 (P3): KEEP as-is.** No new use cases, no invented orchestration, no
consolidation — the value is uniform testable seams + a stable DI surface, and collapsing the
`String`/`NoParams` trivial ones saves little while breaking the pattern. Marked **KEEP** to
avoid over-refactor.

---

## Repository / Data Source Findings

| ID | Sev | Problem | Recommendation |
|----|-----|---------|----------------|
| R1 | P2 | `getOverview` skips DTO→entity mapping (A2) | Add `toEntity()`; map in repo |
| R2 | P2 | Image-mutation contract asymmetry (A3) | Unify to updated-entity return |
| R3 | P3 | DTOs both `extends Entity` and rebuild via `toEntity()` (mild redundancy) | KEEP — repo-wide convention |
| R4 | P3 | Manual `json[..] as T` parsing; only `provider_service_dto` has a parse test | KEEP style; add DTO parse tests (Testing) |
| R5 | P4 | Data sources do no try/catch (delegated to `BaseApiClient`) | KEEP — correct layering |

---

## Model / Entity Findings

- **M1/M2 (KEEP):** Entities pure/immutable/`Equatable`/`const`; DTO-extends-entity + `EntityConverter` is the confirmed convention. Do **not** add a mapper layer.
- **M3 (P2):** `ProviderServiceOverviewDto` omits `EntityConverter`/`toEntity()` — the lone convention break (drives A2/R1). Fix.
- **M4 (P3):** `provider_service_entity` `requests`/`revenue` default 0 outside the detail endpoint — list rows carry 0. Ensure UI never renders these from list-sourced entities.
- **M5 (P4):** `ServicesPagedResult<T>` (in `pagination_meta_entity.dart`) duplicates core's `Page<T>`; bloc converts in `fetchPage`. KEEP (low value to consolidate).

---

## Performance Findings

- **P-1/P-2/P-6 (KEEP):** Plain `ListView` (no forced `shrinkWrap`, no nested scroll), stable `ValueKey(id)` rows, defaults for cache/item extent — all fine.
- **P-3 (P3):** No `buildWhen` on the list `BlocBuilder`; the surrounding page (filter bar, FAB, headers) rebuilds on every `loadingMore` toggle. Add targeted `buildWhen`.
- **P-4 (P3):** Confirm `_skeletonService`/`BoneMock` entity is `static final`, not built per frame.
- **P-5 (P4):** `buildQuery` trims `searchQuery` twice — negligible.

---

## Memory / Lifecycle Findings — **CLEAN**

- **L1 (KEEP):** No `AnimationController`/`StreamSubscription`/`.listen`/`addListener`/`Timer`/`FocusNode`/`PageController`/`TabController`/`NotificationListener` anywhere in the feature. **The old "hidable listener leak" pattern does not exist here.**
- **L2 (KEEP):** All 5 `TextEditingController`s disposed.
- **L3 (KEEP):** Only ScrollController is the shell-owned `MainNavScrollController` — read via inherited widget, never listened/disposed here (correct). Any hidable leak lives in the shell that *provides* it — out of this package's scope.
- **L4 (KEEP):** All post-await `setState`/`emit` are `mounted`/`context.mounted`-guarded.

---

## Scroll / Pagination Findings

State-machine walkthrough (0/1/3/20/many/refresh/scroll/paginate) is all correct **except** the
search-while-paginating and refresh-while-paginating races → **B1** (central epoch fix in
`PaginationMixin` closes both). Empty/short/error/next-page-error footer states all handled.

---

## Search / Filter Findings

- **SF1 (KEEP):** Search is server-side, 350ms debounced, `restartable()` — no stale race *within* search.
- **SF2 (P1):** Search doesn't cancel in-flight load-more → **B1**.
- **SF3 (P2 → SCOPED WORK): "My Services" Status dropdown is dead UI** (`onStatusTap`/`onTypeTap` null; `ServicesListStatusChangedEvent` never dispatched). **Decision: WIRE UP Status** (Active/Inactive), **KEEP Type unwired.** Backend `status∈{active,inactive,all}` confirmed; `all`→null in `buildQuery` already. See **Phase 3**.
- **SF4 (P3):** `_searchController` one-way binding (seeded once from state) — fine unless we set query programmatically.
- **SF5 (P3):** `onQueryChanged` clears rows → full skeleton on each committed keystroke. Acceptable.

---

## Media Upload / Image Findings — **infra already exists**

| ID | Sev | Finding | Evidence |
|----|-----|---------|----------|
| **MU1** | **P1 (bug)** | **Multi-image "only first uploads" = one missing param.** `AddServiceImagesField._pickImages` calls `AssetPicker.pick(options: AssetPickerOptions(allowMultiple: true))` **without `maxSelection`**. `maxSelection` defaults to 1, and `ImagePickerGalleryProvider.pick` truncates the multi-pick via `sublist(0, effectiveMaxSelection)` → all but the first asset discarded before the bloc sees them. | `add_service_images_field.dart:158-169`; `asset_picker/.../image_picker_provider.dart:92-99`; `asset_picker_options` defaults | **Fix:** pass `maxSelection: <maxFiles>` (6 per backend, or the form's `maxFiles`) so the picker returns all selected assets. |
| MU2 | KEEP | `MediaUploadBloc` (`packages/media_upload`) already does: fan-out `Future.wait` over the batch, **bounded** by an internal semaphore (`maxConcurrentUploads`, default 3), **one `media/upload-single` per asset** (multipart `file`), per-item `MediaUploadItem{localId,mediaId,url,progress,status∈pending/uploading/success/failure,failure}`, **retry** (`MediaUploadRetryRequested`), remove, retry-all, and **`MediaUploadExistingItemsSeeded`** for edit prefill. | `media_upload_bloc.dart:45-50,188-274`; `media_upload_item.dart` | Reuse — do NOT build a Services-specific uploader. |
| MU3 | KEEP | Add-service uploads **eagerly at pick time**; submit harvests `item.mediaId` where `isSuccess` and Create is gated on ≥1 success image (matches backend `minItems 1`). Partial failure already isolates: successful images preserved, failed image retryable. | `add_service_page.dart:142-167`; `add_service_form_body.dart:145-155` | KEEP; verify the gate also blocks submit if any *required* image is still uploading/failed per product rule. |
| **MU4** | **P2 (gap)** | **Edit-service ignores images entirely.** `edit_service_form_body.dart` only edits description; `update_provider_service_dto` carries no image ids (correct — `PATCH` can't set images). So a user cannot add/remove images from the Edit form. Post-creation image management exists only on the **Details** page (`manage_service_images_section.dart`, via the sub-resource endpoints). | `edit_service_form_body.dart`; `update_provider_service_dto.dart`; `manage_service_images_section.dart` | **Decision needed (Phase 5):** either (a) leave Edit description-only and rely on Details-page image management (smallest, matches backend split), or (b) add image management to Edit via `MediaUploadBloc` (new files) → `POST /{id}/images` per new mediaId + delete/primary. Recommend (a) unless product requires image editing inside the Edit form. |
| MU5 | P3 | Services renders its own `ServiceImageCard` (Figma) over `MediaUploadTileData` instead of the generic `shared_ui` `MediaUploadTile`. Intentional (Figma-specific). | `service_image_card.dart`; `shared_ui/.../media_upload/*` | KEEP — but confirm no per-frame rebuild churn. |
| MU6 | P3 | `MediaUploadConfig.maxConcurrentUploads` is the default 3 at the Add/RequestNew surfaces; backend `maxItems` is 6. | `add_service_page.dart`, `request_new_service_page.dart` DI | KEEP 3 (sensible bound) — or set explicitly with a comment tying it to network conventions. |

**Net:** The multi-image work stream is a **one-line picker fix (MU1)** + a **config/gate verification** + the **Edit-image decision (MU4)** + tests — not new infrastructure.

---

## Error Handling Findings

- **E1/E2 (KEEP):** data source throws → `ErrorMapper`→`Failure`(sealed)→`TaskEither`→bloc `fold`; UI uses `failureErrorDisplay`; first-page→`AppErrorState`, next-page→retry footer, mutations→error snackbar. Consistent.
- **E3 (P3):** Ensure `ValidationFailure.fieldErrors` from create/edit are surfaced on the offending form fields, not only a generic snackbar.

---

## Loading / Skeleton Findings

- **LS1 (KEEP):** First-page load skeletonizes real rows via `AppSkeletonList`+`BoneMock`; details via `AppSkeletonizer`. No bespoke skeleton infra — correct.
- **LS2 (P3):** Verify `AppSkeletonizer.enabled` binds to **first-page loading only**, not `loadingMore` (else the whole list shimmers during pagination).
- **LS3 (P4):** Confirm shimmer stops exactly at `status==success`.

---

## UI / UX Technical Findings

- **UX1 (P2):** Dead Status dropdown resolved by Phase 3 (wire up); Type stays visible-but-inert by design.
- **UX2 (P3):** M4 — never render `revenue`/`requests` from list-sourced entities.
- **UX3 (P3):** RTL/localization — verify all list/empty/error/chip strings are keys; date format (`service_date_format.dart`) locale/RTL-aware.
- **UX4 (P4):** Touch targets (filter chips, image delete) ≥48dp via tokens.
- **UX5 (KEEP):** Retry UX, mutation fold-in, post-return refresh all coherent.

---

## Dependency Findings

- **D1 (P3):** `easy_localization` + `localization` redundancy — verify/drop.
- **D2 (P3):** `flutter_screenutil` in `dev_dependencies` but runtime UI lib — confirm test-only or move.
- **D3/D4 (KEEP):** No direct `dio`/`get_it` (transitive, correct); `fpdart` consistent.

---

## Code Quality Findings

- **CQ1 (P3):** Stray untracked `flutter_0*.log` files across packages — `.gitignore`/clean up.
- **CQ2 (KEEP):** No `print`/`debugPrint`/commented-out/`dynamic` force-unwrap found (verify with a Phase 0 grep sweep).
- **CQ3 (KEEP):** Doc comments are thorough and accurate — a strength.

---

## Testing Gaps

Current: 10 test files (routes, `provider_service_dto` parse, presentation models, navigation,
widget bodies). **No `test/src/presentation/bloc/` directory** — the most BLoC-heavy package has
zero BLoC tests, while `workers`/`branches` have them. Priority additions:

1. **`ServicesListBloc`** (port `workers_list_bloc_test.dart`): first page, append+dedup, search-restart, **status-filter reset to page 1**, first-page error, next-page error keeps rows.
2. **B1 regression:** interleave load-more(page2, queryA) with search(queryB) → final state contains only queryB page-1 items + queryB meta.
3. **`ServiceActionBloc`:** delete/status success + failure fold-in; `droppable` double-tap.
4. **`RequestNewServiceBloc`:** post-B3 `droppable` prevents double submit.
5. **Multi-image (MU1):** picker returns N assets with `maxSelection`; `MediaUploadBloc` all-success collects N mediaIds; partial failure keeps successes + retries only the failure; original order preserved; edit seeds existing without re-upload (MediaUploadExistingItemsSeeded).
6. **DTO parse tests** for untested DTOs (overview, category_record, service_request, catalog); extend `provider_service_dto` nested/flattened fallbacks; overview DTO→entity after A2.

---

## Existing SANAD Patterns To Reuse

| Need | Reuse | Status in Services |
|------|-------|--------------------|
| Pagination state machine | `core/.../pagination_mixin.dart` | Used ✓ (gets epoch fix) |
| Paged list UI | `shared_ui/.../sanad_paged_list.dart` + `paging_state_adapter.dart` | Used ✓ |
| Skeletons | `shared_ui/.../app_skeletonizer.dart`, `app_skeleton_list.dart` | Used ✓ |
| Mutation feedback | `shared_ui/.../mutation_listener.dart` + `app_progress.dart` | Snackbar today; optional for add/edit blocking UX |
| Empty/error | `shared_ui/.../app_empty_state.dart`, `app_error_state.dart` | Used ✓ |
| Failure→copy | `localization/.../failure_error_display.dart` | Used ✓ |
| **Multi-file upload** | **`media_upload/.../media_upload_bloc.dart`** (bounded concurrency, per-item, retry) | **Used ✓ — just fix picker `maxSelection`** |
| Bounded concurrency | (only the semaphore *inside* `MediaUploadBloc`; no standalone pool exists) | Reuse the bloc's bound; don't build a pool |
| BLoC tests | `workers/test/.../workers_list_bloc_test.dart` | **Missing — port it** |

---

## Recommended Target Architecture

The **current** architecture, hardened:

- `PaginationMixin` gains a **fetch epoch** (B1/SF2/refresh race — fixed repo-wide).
- All mutation blocs uniformly `droppable()` (B3); `Fetch` symmetric with `refresh` (B2).
- Overview DTO conforms to `EntityConverter` (A2/M3/R1); image mutations share one return contract (A3/R2).
- **Status filter wired** (Active/Inactive) via existing enum/query; **Type kept visible + unwired**.
- **Multi-image upload fixed** via picker `maxSelection` (MU1); Edit-image decision resolved (MU4).
- BLoC test parity with `workers`.
- Everything else unchanged (layering, use cases, DTO convention, shared widgets, lifecycle, skeletons, `MediaUploadBloc`).

---

## Refactoring Plan (phased, independently reviewable)

### Phase 0 — Characterization tests + cleanup (safety net)
- **Goal:** Lock current behavior; stand up BLoC-test scaffolding.
- **Files:** new `test/src/presentation/bloc/services_list/…_test.dart`, `.../service_action/…_test.dart`; extend `data/models/provider_service_dto_test.dart`; `.gitignore` the `flutter_*.log` files; grep sweep (`print`/`debugPrint`/`dynamic`/TODO).
- **Changes:** Port `workers_list_bloc_test.dart` (mocktail + bloc_test) covering load/append/dedup/search/status/error **as they behave today** (B1 case marked `skip`, flips green in Phase 2).
- **Deps:** none. **Risks:** none (tests). **Verify:** `fvm flutter test`. **Outcome:** regression net.

### Phase 1 — Data/domain consistency (low risk)
- **Goal:** A2/M3/R1 (overview mapping) + A3/R2 (image-mutation contract).
- **Files:** `data/models/provider_service_overview_dto.dart` (+`EntityConverter`/`toEntity()`), `data/repositories/provider_services_repository_impl.dart` (map overview; unify addImage/setPrimary/deleteImage to return updated entity — all three endpoints already return the detail DTO).
- **Deps:** Phase 0. **Risks:** low. **Tests:** overview mapping; image-mutation repo tests.
- **Verify:** `fvm flutter test`; `fvm flutter analyze`. **Outcome:** uniform contract.

### Phase 2 — Concurrency hardening (the real fix)
- **Goal:** B1/SF2/refresh race + B2 + B3.
- **Files:** `packages/core/lib/src/pagination/pagination_mixin.dart` (epoch); `services_list_bloc.dart` + `service_requests_list_bloc.dart` (`Fetch` transformer); `request_new_service_bloc.dart` (`droppable()`); add `packages/core` pagination_mixin tests.
- **Changes:** `int _epoch`; bump in `loadFirstPage`/`refresh`/`onQueryChanged`; capture at `_fetch` start; `if (epoch != _epoch) return;` before emit. Add `droppable()` to the two `Fetch` events + request-new submit.
- **Deps:** Phase 0 (flip skipped B1 test). **Risks:** medium — shared by `workers`; run its tests too.
- **Tests:** B1 interleave (green); refresh-vs-load-more; `workers` tests still green.
- **Verify:** `fvm flutter test` in `services`, `workers`, `packages/core`; `analyze`. **Outcome:** no stale request overwrites a newer one, repo-wide.

### Phase 3 — Status filter wiring (KEEP Type)
- **Goal:** SF3/UX1 — wire Status (Active/Inactive), keep Type visible + inert.
- **Files:** `widgets/services_filter_bar.dart` (pass real `onStatusTap`, keep `onTypeTap` reserved/no-op with a doc comment), `pages/services_page.dart` (dispatch `ServicesListStatusChangedEvent(status)` from the Status dropdown; seed selected chip from `state.statusFilter`).
- **Changes:** Map dropdown selections → `ProviderServiceStatus.active/inactive` (and an "All" option → `.all`). No new enum, no local filtering. Status change already resets to page 1 via `onQueryChanged`; `buildQuery` already sends `status`/omits on `all` and composes with `search`. Verify refresh preserves both (mixin `refresh` preserves query — confirm).
- **Deps:** Phase 2 (uses hardened query path). **Risks:** low-medium (visible UI).
- **Tests:** bloc test — status change resets page 1 + sends `status`; `search`+`status` combined query; refresh preserves both; widget test — Type dropdown still renders, its callback is inert.
- **Verify:** `fvm flutter test`; manual (Active/Inactive filter; search+status; Type visible/no-op). **Outcome:** functional Status, intentionally-inert Type.

### Phase 4 — Multi-image upload fix + verification
- **Goal:** MU1 bug + MU3/MU6 verification.
- **Files:** `widgets/add_service_images_field.dart` (add `maxSelection:` to the `AssetPickerOptions` — value = form `maxFiles`, capped at backend max 6); confirm `request_new_service` uses the same field/fix; optionally set `MediaUploadConfig.maxConcurrentUploads` explicitly at the Add/RequestNew surfaces with a comment.
- **Changes:** one-line picker param; verify submit gate requires ≥1 success + blocks while any selected image is uploading/failed (backend `minItems 1`); verify original selection order is preserved in the tiles and in the harvested `imageIds`.
- **Deps:** none hard. **Risks:** low. **Tests:** MU1 tests (see Testing #5) — picker N assets, all-success N mediaIds, partial-failure isolation + retry-only-failed, order preserved.
- **Verify:** manual — select 3–6 images in one gallery interaction → all preview, concurrent uploads, one fails → identifiable + retry, successes not re-uploaded, correct mediaIds on Create. **Outcome:** multi-image upload works as specified with zero new infra.

### Phase 5 — Edit-image decision + UI/UX + polish
- **Goal:** MU4 decision; UX2/E3/LS2; P-3/P-4; deps D1/D2; B5 (optional).
- **Files (option a, recommended):** none for Edit images (rely on Details-page management); `service_list_item.dart`/`service_metrics_section.dart` (UX2 guard); form bodies (E3 field errors); skeleton `enabled` binding (LS2); `services_page.dart` (`buildWhen`); skeleton entity `static final`; `pubspec.yaml` (D1/D2).
- **Files (option b, if product wants Edit images):** wire `MediaUploadBloc` into `edit_service_form_body.dart` seeded via `MediaUploadExistingItemsSeeded`; on save, `POST /{id}/images` per new mediaId + delete/primary for removals/primary changes (two-stage, since PATCH is description-only).
- **Deps:** Phases 2-4. **Risks:** low (a) / medium (b). **Tests:** per chosen option; UX2/E3 widget tests.
- **Verify:** `analyze`; `test`; manual Edit flow. **Outcome:** consistent image UX; cleaner rebuilds/deps.

---

## Migration Order (safest)

`Phase 0 → 1 → 2 → 3 → 4 → 5`. Tests first; low-risk data consistency; shared-mixin concurrency
fix (gated by the net, run against `workers`); Status wiring; the picker bug fix; UI/edit/polish
last. Each phase is independently reviewable and shippable.

---

## Final Recommendation

### Must Fix (P1)
- **B1/SF2/refresh race** — `PaginationMixin` fetch epoch (stale request overwrites newer).
- **B3** — `RequestNewServiceBloc` missing `droppable()` (duplicate submits).
- **MU1** — picker `maxSelection` (the actual multi-image bug).

### Should Fix (P2)
- **A2/M3/R1** overview DTO→entity; **A3/R2** image-mutation contract; **B2** Fetch transformer.
- **SF3/UX1** — wire Status filter, keep Type.
- **MU4** — resolve Edit-image handling.
- **Testing** — add `ServicesListBloc`/`ServiceActionBloc` bloc tests (parity with `workers`).

### Nice To Have (P3/P4)
- `buildWhen`; static skeleton; dep dedupe; inline-debounce→core `Debouncer`; DTO parse tests; field-level validation errors; `.gitignore` stray logs; explicit `maxConcurrentUploads`.

### Keep As-Is (do NOT change)
- Clean-arch layering; 17 thin use cases; DTO-extends-entity+`EntityConverter`; manual JSON style; `PaginationMixin`/`SanadPagedList`/`AppSkeletonizer`/`AppRefreshIndicator`/`failureErrorDisplay`; **`MediaUploadBloc`** (bounded concurrency, per-item, retry — reuse, don't rebuild); two scoped `ServiceActionBloc` instances; lifecycle (no leaks, no hidable bug); shell-owned `MainNavScrollController`; error pipeline; **Type filter (visible, unwired)**; `media/upload-single` per-image (no batch endpoint).

---

## Definition of Done

- [ ] B1 regression test green; no stale query/refresh overwrites a newer one (verified in `services`, `service_requests`, `workers`).
- [ ] `RequestNewServiceBloc` submit `droppable()`; double-tap test green.
- [ ] `Fetch` transformer-symmetric with `refresh`.
- [ ] Overview goes through DTO→entity; image mutations share one documented contract.
- [ ] **Status filter functional** (Active/Inactive, resets page 1, composes with search, survives refresh); **Type dropdown still rendered and intentionally inert** (test asserts both).
- [ ] **Multi-image:** one gallery selection of 3–6 images → all enter queue → `media/upload-single` once per image → bounded concurrent → independent success/failure → retry only failed → successes preserved → original order preserved → correct mediaIds on Create.
- [ ] Edit-image handling resolved per chosen option (default: description-only + Details-page management).
- [ ] `ServicesListBloc`+`ServiceActionBloc` bloc tests pass; DTO parse tests extended.
- [ ] `fvm flutter analyze` clean; `fvm flutter test` green for `services`, `workers`, `core`, `media_upload`.
- [ ] No `revenue`/`requests` rendered from list-sourced entities; deps deduped; stray logs ignored.
- [ ] Report saved at `apps/sanad_provider/packages/services/services-feature-audit-and-refactoring-plan.md`.

### Locked decisions (from user)
- Status filter: **wire up** (Active/Inactive). Type filter: **keep visible, do not wire, do not fake, do not invent a query param.**
- Multi-image upload: **bounded concurrent** `media/upload-single` per image, **no batch endpoint**, **not sequential**, per-image retry, preserve order — via the existing `MediaUploadBloc` (fix the picker).
- Report lives **inside the package**.

### One open sub-decision (non-blocking, Phase 5)
- **MU4 — Edit-service images:** default = description-only (rely on Details-page image management, matching the backend `PATCH`-is-description-only split). Switch to full Edit-image management (option b) only if product requires editing images from the Edit form.
