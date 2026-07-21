# SANAD Architecture Blueprint

> **Purpose.** This is the single architectural reference for error, success, mutation,
> retry, logging, offline, and API-contract handling across the SANAD Flutter monorepo.
> It is intended for onboarding new engineers and for guiding future feature work.
>
> **How this document was produced.** Consolidated from three verified audits against the
> live codebase and the live OpenAPI spec (`https://dev-api.trysanad.us/api/docs-json`) plus
> real API probes. Every "Current architecture" statement is grounded in the implementation.
>
> **Status legend for each section:**
> - **Current architecture** — what the code does today (verified).
> - **Approved architecture** — the *canonical target* this blueprint sets. ⚠️ These are
>   **proposed conventions pending team ratification**, not yet-implemented code and not a
>   claim that any refactor has been approved.
> - **Known technical debt** — verified gaps between Current and Approved.
> - **Future evolution** — longer-horizon direction once the debt is paid.
>
> **Golden rule.** The `Failure` abstraction must be pure: transport/HTTP concepts flow
> *up* only as far as `ErrorMapper`, business meaning flows *down* only as far as the Bloc,
> and the UI/Design System speak neither HTTP nor `Failure` internals.

---

## Implementation status — Epic 1 (updated 2026-07-21)

Epic 1 (Error Handling Unification) implemented much of the **Approved architecture** below.
The per-section "Current architecture" prose is retained as the **pre-Epic audit baseline**;
each affected section now carries an **✅ Epic 1 update** note and the debt register (§17) is
marked with status. Legend: ✅ done · 🟡 partial · ⛔ backend-gated · ⬜ open.

| Area | Status | What shipped |
|---|---|---|
| Failure taxonomy (§6) | ✅ | `ValidationFailure` now produced (all messages); added `BusinessRuleFailure`, `ConflictFailure`, `RateLimitFailure`; `isRetryable` added |
| Failure resolver (§5,§7) | ✅ | `FailureLocalizer` (localization) — one resolver; `contains(' ')` heuristic removed |
| Error components (§5) | ✅ | `AppErrorState`, `AppValidationSummary`, `showAppErrorSnackbar`; duplicated `_ErrorState` removed |
| Bloc state contract (§4) | ✅ | auth/otp/forgot_password now carry the `Failure` object; `services` moved onto a `Cubit` |
| Retry policy (§10) | ✅ | `isRetryable` gates retry UI; interceptor backoff + jitter, `maxRetries=2` |
| Logging (§11) | ✅ | Loggers unified; `AppBlocObserver` → `ErrorReporter` (single owner) |
| Global handlers (§12) | 🟡 | `runZonedGuarded` + `FlutterError`/`PlatformDispatcher.onError` + release `ErrorWidget` installed; **Crashlytics activation pending Firebase config** |
| Refresh / staleness (§9,§15) | ✅ | mutation → `pop(true)` → list refresh; workers-add staleness fixed |
| Status mapping (§2,§16) | ✅ | 409→Conflict, 429→RateLimit, business-400→BusinessRule; request-shape mismatches resolved |
| Machine error codes (§16) | ⛔ | backend still returns no `errorCode`; client seam ready (preserved in metadata) |
| 403 prose-sniffing removal (§2) | ⛔ | kept as fallback — needs backend codes first |
| Success representation unify (§8) | ⬜ | deferred (high-churn/low-value on working code) |
| Dead code / maps regime / pinning (§17) | ⬜ | D9, D11, D12 largely open |

---

## Table of Contents

1. [Layer Responsibilities](#1-layer-responsibilities)
2. [Network Responsibilities](#2-network-responsibilities)
3. [Repository Responsibilities](#3-repository-responsibilities)
4. [Bloc Responsibilities](#4-bloc-responsibilities)
5. [Design System Responsibilities](#5-design-system-responsibilities)
6. [Failure Taxonomy](#6-failure-taxonomy)
7. [Failure Lifecycle](#7-failure-lifecycle)
8. [Success Lifecycle](#8-success-lifecycle)
9. [Mutation Lifecycle](#9-mutation-lifecycle)
10. [Retry Policy](#10-retry-policy)
11. [Logging Policy](#11-logging-policy)
12. [Global Exception Handling](#12-global-exception-handling)
13. [Offline Architecture](#13-offline-architecture)
14. [Navigation Conventions](#14-navigation-conventions)
15. [Refresh Conventions](#15-refresh-conventions)
16. [API Contract Conventions](#16-api-contract-conventions)
17. [Consolidated Technical-Debt Register](#17-consolidated-technical-debt-register)

---

## 1. Layer Responsibilities

The stack, top to bottom: **Backend → Network → Repository → UseCase → Bloc → UI → Design System**, with **Global Handlers** as a cross-cutting last-resort tier.

### Ownership matrix (who owns which error family)

Error families: **T** transport/connectivity · **P** HTTP protocol · **B** business/domain · **L** local/device · **X** programming · **R** rendering.

| Layer | Originates | Passes through | Must never handle |
|---|---|---|---|
| Backend | B, P (+ machine codes) | — | T, L, X, R |
| Network | T, session/refresh | P→Failure translation | **B classification**, UI copy |
| Repository | L (cache/storage) | T, P, B from below | transport catching, HTTP→Failure mapping |
| UseCase | B (pure-domain rules) | everything below | transport / HTTP concerns |
| Bloc | Failure→UI-state, surface decision | the `Failure` **object** intact | re-classification, HTTP knowledge, flattening to `String` |
| UI | surface selection, retry wiring, `Failure`→localized message | resolved strings to DS | HTTP/Dio/`Failure.code`-as-status |
| Design System | presentation primitives (how errors *look*) | pre-resolved strings + callbacks | `Failure` types, i18n keys, business meaning |
| Global Handlers | last-resort capture, crash reporting, logging policy | — | feature-specific UX |

### Current architecture
The data-side spine (Network → Repository → UseCase) is clean and centralized. Divergence and vacuums concentrate at **three boundaries**: network↔business (classification leaking down, HTTP leaking up), bloc↔UI (state contract), and the near-absent global tier.

### Approved architecture
Each layer owns exactly one column above. The three golden boundaries:
1. Business meaning is assigned **at or above the Bloc**, never inside `ErrorMapper` from prose.
2. HTTP artifacts (status, server prose) never travel past `ErrorMapper` except inside `Failure.metadata` (for logs, not UX).
3. Every operation outcome has an owner for its "after" (refresh, feedback, logging).

### Known technical debt
- `ErrorMapper` performs **business classification** (403 → `UnverifiedUserFailure` via English substring match, `error_mapper.dart:88-99`).
- HTTP leaks to UI: `Failure.code` is an HTTP status string; UI branches on it and renders raw server prose.
- No last-resort owner for errors escaping a bloc `.fold`, bloc-less flows, or `build()` failures.

### Future evolution
A dependency-rule lint (extend `dep_rules.yaml`) that fails the build if `dio`/HTTP symbols appear above the network package, or if `Failure.code` is read in `presentation/`.

---

## 2. Network Responsibilities

Package: `packages/network`.

### Current architecture
- **Single conversion point:** `ErrorMapper.mapError` (`error_mapper.dart:19-159`) converts Dio/Socket/Timeout → `Failure`. Invoked once, in `ApiClientImpl.request` (`api_client_impl.dart:33`). No Dio type leaks past this class.
- **Public contract:** `BaseApiClient.request → TaskEither<Failure, T>` (lazy).
- **Interceptor chain** (registration = execution order, `app_di.dart:81-96`): `AcceptLanguage → Auth → RetryOnTimeout → TimeoutError → Logging`.
- **`NetworkGuard`** pre-checks connectivity and short-circuits offline requests to `Left(NoInternetFailure)` (`network_guard.dart:12-20`).
- **Token/refresh:** `AuthInterceptor` does 401 → refresh (mutex + `Completer` queue) → retry once (`_authRetried`), refresh via raw un-intercepted Dio; failure → `_logout` → `onUnauthorized` → `AuthStatusNotifier`.
- **`FailureMapper`** is a documented "canonical" alias with **zero call sites**.

### Approved architecture
- Network owns **transport** (`NoInternetFailure`, `TimeoutFailure`, `SecureConnectionFailure`, cancel) and **session/refresh** only.
- `ErrorMapper` translates HTTP **status → Failure** and, when a machine-readable backend error code exists, **code → Failure**; it must **not** infer business meaning from prose.
- Exactly one mapper symbol. One logging hook at the mapper (see §11).
- Raw server prose retained only in `Failure.metadata`, never as the user-facing `message`.

### Known technical debt
- 403 business classification via English substring matching (locale-fragile).
- 400/409/422 all collapse to `ServerFailure`; validation `message` **array → only first element** kept (`_flattenField`, `error_mapper.dart:187`).
- `FailureMapper` dead; `ApiErrorResponse` model + its `_parseFieldErrors` fully dead.
- `SecureTransport*` pinning is **scaffolding only** — never wired (`badCertificateCallback`/adapter absent); those mapper branches are dead.
- No `CancelToken` in the main request path (`ApiClientImpl` bypasses `SecureDioClient` methods); `transformTimeout` not retried.
- Refresh-queue **race**: a 401 in the resolve/reset window can enqueue onto a cleared queue and hang until its own timeout.
- Connectivity = interface-presence, not reachability (captive portals report online).

**✅ Epic 1 update:** validation now maps to `ValidationFailure` (all messages preserved); **409→`ConflictFailure`, 429→`RateLimitFailure`, single-string 400→`BusinessRuleFailure`**. Interceptor retry now uses exponential backoff + jitter (§10). Still open/gated: 403 prose-sniffing (backend-gated), dead `FailureMapper`/`ApiErrorResponse`, TLS pinning, `CancelToken`, reachability. The refresh-queue "race" was assessed and found **not reproducible on Dart's single isolate** (no `await` between `_resolveQueue()` and clearing `_isRefreshing`) — left unchanged.

### Future evolution
- Adopt a code-first mapping table once the backend exposes stable error codes (see §16).
- Implement real TLS pinning **or** remove the dead security scaffolding.
- Reachability-based connectivity; `CancelToken` propagation for cancellable screens.

---

## 3. Repository Responsibilities

### Current architecture
- Backend repos are **pure `TaskEither` composition**: `_apiClient.request(...).map((dto) => dto.toEntity())`, no `try/catch`, no HTTP knowledge. Consistent across auth, branches, workers, services.
- Legitimate local `TaskEither.tryCatch` only at **non-Dio boundaries**: Hive (`auth_local_datasource.dart:48-59` → `CacheFailure`) and device SDKs in maps `services/*`.
- `packages/domain`'s `auth_repository`/`user_repository` contracts are **unused in production** (test mocks only) — a parallel legacy layer.

### Approved architecture
- Repositories map DTO→entity on success and **pass failures through untouched**.
- The **only** place repos may originate a `Failure` is a genuine local/device boundary (cache, storage, device permission), and even then the message must be a **key or resolved concept**, never `error.toString()`.
- One domain-contract location per feature; delete the unused parallel `packages/domain` repos or make them the single source.

### Known technical debt
- maps `services/*` originate `LocationFailure`/`UnknownFailure` with **`error.toString()`** as the user message (`geocoding_service_impl.dart:61`, `open_location_settings_usecase.dart:14`).
- Duplicate/parallel repository contracts (`packages/domain` vs feature-local).

### Future evolution
- A shared `LocalBoundaryFailureMapper` for device/SDK errors mirroring `ErrorMapper`, so maps stops hand-rolling.

---

## 4. Bloc Responsibilities

### Current architecture
- Convention: `await useCase(params).run(); result.fold(failure→state, data→state)` — hand-rolled in every feature.
- `BaseRequestBloc` (`base_request_bloc.dart`) — the intended generic bloc with `Fetch/Refresh/Retry` events + `LocaleChangeBus` auto-refresh — is **never instantiated** (dead).
- **State payload is inconsistent:**
  - `Failure` **object**: branches, workers (3 blocs), maps (3 blocs).
  - Flattened **`String`**: auth, otp, forgot_password (lose type/code/metadata).
- **Success signal** is modeled 4 ways: typed `SuccessState`, `RequestStatus.success` enum, `isSuccess` bool, and (services) no bloc at all — usecase called via `sl<>()` inside a widget (`select_service_action_sheet.dart:82`).

### Approved architecture
- Blocs carry the **`Failure` object** in state — never a `String`. Type/code/metadata must survive to the UI.
- Blocs decide **which surface** a failure uses (snackbar vs inline vs full-screen) but never re-classify or read HTTP status.
- One canonical success representation (a typed success state or a shared status enum) so feedback/refresh can be handled uniformly.
- Every feature routes through a bloc/cubit; no direct `sl<UseCase>()` calls from widgets.

### Known technical debt
- `BaseRequestBloc` + `RefreshEvent`/`RetryEvent` dead → every feature reinvents `.run()+.fold()`.
- Object-vs-`String` state split; auth compensates by re-classifying `UnverifiedUserFailure` in the bloc (`auth_bloc.dart:64`).
- services bypasses the bloc layer entirely.
- Success message stored as raw `String` (e.g. `AuthLogoutSuccessState('auth.logout_success')`).

**✅ Epic 1 update:** the **object-vs-`String` split is resolved** — auth/otp/forgot_password failure states now carry the `Failure` object. **`services` now routes through `ServicesCubit`** (no more `sl<UseCase>()` in a widget). Still open: `BaseRequestBloc` remains dead (adopt-or-delete pending); success-*message* strings and the 4 success-*state* representations are unchanged (deferred, see §8).

### Future evolution
- Either adopt `BaseRequestBloc` repo-wide or delete it; do not leave a dead "canonical" abstraction.

---

## 5. Design System Responsibilities

Package: `packages/design_system`. **DS owns how things look; it must stay ignorant of `Failure` and i18n keys.**

### Current architecture
Present and healthy:
- Loading: `AppLoadingIndicator`, `AppShimmer`, `AppProgressBar`, `AppProgressDialog`.
- Empty: `AppEmptyState`, `AppGenericEmptyState`.
- Network error: `AppNetworkFailureState` (inline+retry), `AppNetworkErrorPage` (full-screen offline).
- Feedback: `AppSnackbar`, `AppSuccessPopover`, `AppPopover`, `AppConfirmationContent`, `AppActionSheet`, `AppBottomSheet`.
- Per-field validation: error slots in `app_text_field`, `app_phone_field`, `app_select_field`, `app_search_field`.

Missing → re-invented in features:
- No generic **(non-network) error state**, no generic **retry state** (retry is bundled only inside the two network widgets), no **validation summary**, no generic **error dialog**, no non-blocking **offline banner**.

### Approved architecture
DS **should own error presentation**, via failure-agnostic primitives that receive resolved strings + callbacks:
- `AppErrorState({title, message, onRetry})` — generic error/retry.
- `AppErrorDialog`, `AppValidationSummary` (aggregate multi-error), optional `AppOfflineBanner`.
- Contract: DS components take **strings and callbacks only** — never `Failure`, never i18n keys.

### Known technical debt
- `_ErrorState` duplicated privately in `branches_page.dart:292`, `workers_page.dart:232`, and `invitations_content.dart:122`.
- Network error widgets reused for non-network failures (wrong copy/illustration for 500/timeout).
- `AppSnackbar` overloaded: errors, successes, and "coming soon" share the neutral `dark` style; only `add_branch_error_snackbar.dart:19` uses `AppSnackbarColor.error`.

**✅ Epic 1 update:** added **`AppErrorState`** (generic error/retry, replaces the duplicated private `_ErrorState` across workers/branches/invitations/worker-details), **`AppValidationSummary`**, and **`showAppErrorSnackbar`** (consistent error styling). Non-network failures now use generic copy. Still open: `AppErrorDialog` and `AppOfflineBanner` (no consumer yet).

### Future evolution
- A DS "feedback catalog" documenting exactly one component per outcome (error / retry / validation / empty / loading / success), enforced in review.

---

## 6. Failure Taxonomy

Location: `packages/core/lib/src/domain/failures/failure.dart` (`sealed Failure` with `message`, `code`, `metadata`).

### Current architecture — 12 subtypes
Business-shaped (good): `NoInternetFailure`, `TimeoutFailure`, `SecureConnectionFailure`, `CacheFailure`, `LocationFailure`, `UnverifiedUserFailure`, `UnauthorizedRoleFailure`.
HTTP-shaped / overloaded: `UnauthorizedFailure` (401), `ServerFailure` (404 **and** 5xx **and** 400 **and** 409/422), `NetworkFailure` (vague, near-dead).
Defined-but-never-produced: `ValidationFailure`.
Fallback: `UnknownFailure`.

`FailureKindX` (`failure_extensions.dart`) provides boolean checks only — **no message resolution**.

### Approved architecture
Every `Failure` names a **business concept**, not an HTTP artifact. Target set:
- Transport: `OfflineFailure` (rename of `NoInternetFailure`), `TimeoutFailure`, `SecureConnectionFailure`.
- Auth/session: `SessionExpiredFailure`, `InvalidCredentialsFailure`, `PermissionFailure` (role), `UnverifiedUserFailure`.
- Business: `ValidationFailure` (carrying **all** messages / field map), `ConflictFailure`, `BusinessRuleFailure`, `RateLimitFailure`.
- Local/device: `CacheFailure`, `LocationPermissionFailure`, `LocationUnavailableFailure`.
- Fallback: `UnknownFailure`.
- Add a **`bool get isRetryable`** dimension (feeds §10).
- Make intermediate subtypes `final`/`sealed` so exhaustiveness actually holds.

### Known technical debt
- `ServerFailure` is a **four-way catch-all** (404/5xx/validation/conflict indistinguishable).
- `UnauthorizedFailure` conflates no-token / expired / bad-credentials.
- `LocationFailure` conflates permission / unavailable / geocode-fail (distinguished only by a `code` string).
- `ValidationFailure` never constructed; `NetworkFailure` overlaps `NoInternetFailure`.
- `sealed` is skin-deep — maps extends non-final intermediates from another package.
- No `isRetryable`, no `ConflictFailure`/`SessionExpiredFailure`/`BusinessRuleFailure`/`RateLimitFailure`.

**✅ Epic 1 update:** `ValidationFailure` **is now produced** (carries all messages + optional `fieldErrors`); added **`BusinessRuleFailure`, `ConflictFailure`, `RateLimitFailure`** and **`isRetryable`**. `ServerFailure` is now narrower (404 + 5xx; 400/409 split off). Still open: `UnauthorizedFailure`/`LocationFailure` still conflated; `SessionExpiredFailure` deferred (needs interceptor context); intermediate subtypes still not `final` (sealing conflicts with the `maps` package — see D9).

### Future evolution
- 1:1 backend-error-code → `Failure` mapping (see §16) so the taxonomy is contractual, not heuristic.

---

## 7. Failure Lifecycle

### Current architecture
```
Dio throws → interceptors (401 refresh / timeout retry) → ErrorMapper.mapError → Failure
  → NetworkGuard (offline short-circuit) → TaskEither<Failure,T>
  → RemoteDataSource (passthrough) → Repository (.map on success) → UseCase (passthrough)
  → Bloc (.run().fold) → State (Failure OBJECT or flattened STRING)
  → UI (BlocListener) → surface (snackbar / _ErrorState / /offline) → message via .tr()
```
Message resolution is inconsistent: `contains(' ') ? raw : .tr()` heuristic (branches/workers) vs unconditional `.tr()` (auth/otp) vs hardcoded English (maps).

### Approved architecture
- One conversion point (`ErrorMapper`), one logging hook there (§11).
- `Failure` object survives intact to the UI.
- **One** central `Failure → localized message` resolver in the UI layer (keyed off failure *type*, not string inspection); DS receives the resolved string.
- Raw server prose lives only in `metadata`.

### Known technical debt
- Object-vs-`String` flattening (auth/otp/forgot_password).
- Brittle `contains(' ')` message heuristic; raw server English can reach users.
- Dead localized keys (`errors.unauthorized/not_found/bad_request/invalid_credentials`) because the mapper emits raw prose instead of these keys.

**✅ Epic 1 update:** the **`contains(' ')` heuristic is removed** — one resolver (`FailureLocalizer` in `localization`) maps each `Failure` to a localized string, translating dotted i18n keys and passing backend prose through. The `Failure` object now survives intact to the UI. Raw prose→metadata-only remains a future step (blocked on backend error codes).

### Future evolution
- Delete the heuristic once every `Failure` maps deterministically to a key.

---

## 8. Success Lifecycle

Stages: **Backend → Repository → UseCase → Bloc → UI → Feedback → Navigation → Refresh.**

### Current architecture
Consistent through the usecase layer; fragments above it:
- **Signal:** typed `SuccessState` (auth/otp/forgot_password) · `RequestStatus.success` (branches) · `isSuccess` bool (workers) · `setState` (services).
- **Feedback:** success popover (workers add `add_worker_page.dart:125`, branches add) · silent (workers edit, auth) · forward-navigation-as-feedback (auth/otp).
- **Navigation:** `pop()` (adds) · `pop(updatedWorker)` result-threading (edit `edit_worker_page.dart:143`) · `go`/replace (auth/otp).
- **Refresh:** see §15 — no single strategy.

### Approved architecture
- One canonical success representation across features.
- Explicit, consistent feedback policy (see §14): mutations confirm; reads don't.
- Post-success refresh has a defined owner (see §15).
- Success messages are keys resolved centrally, not raw strings in state.

### Known technical debt
- 4 success-modeling styles; inconsistent/absent feedback; success message stored as raw `String`.
- No domain/business event emitted on success (see §11).

### Future evolution
- A shared success/feedback mixin or bloc base once the success representation is unified.

---

## 9. Mutation Lifecycle

### Current architecture
- Data layer for mutations is **real and consistent** — workers delete/status/invite/resend/cancel/update all hit the API (`worker_remote_data_source.dart`), backed by dedicated DTOs. (The historical fake `Future.delayed` worker stubs are fully remediated.)
- Typical UI flow: `showAppProgressDialog` (blocking) → success popover → `pop()`; failure → error snackbar.
- **No optimistic updates.** **No event-driven list invalidation** after a write.

### Approved architecture
- Mutation = **blocking progress → outcome feedback → navigate → invalidate source**.
- Source-of-truth list is refreshed via an explicit signal (event-driven or result-threaded), never left stale.
- Conflicts/business-rule failures (currently 400) surface as `ConflictFailure`/`BusinessRuleFailure`, not generic errors.

### Known technical debt
- Post-mutation freshness has **no owner**: workers-add does `pop()` while `workers_page` launches `push(add)` un-awaited and does not re-fetch (`workers_page.dart:201,224`) → **staleness risk**. edit uses `pop(updatedWorker)` result-threading (different pattern).
- Business conflicts indistinguishable from validation (both `ServerFailure(400)`).

**✅ Epic 1 update:** **post-write refresh now has an owner** — a mutation pops `true` and the owning list bloc refreshes on return (workers-add staleness fixed; see §15). Business conflicts now surface as `BusinessRuleFailure`/`ConflictFailure`, distinct from `ValidationFailure`. Optimistic updates still not used.

### Future evolution
- Consider a lightweight repository cache / stream so mutations invalidate reads automatically.

---

## 10. Retry Policy

### Current architecture — three uncoordinated owners
- **Auto (network):** `RetryOnTimeoutInterceptor` (timeouts only, `maxRetries=1`, 400ms); `AuthInterceptor` (401 refresh+retry once).
- **Semi-auto:** `ConnectivityController.check()` behind `/offline`.
- **Manual (UI):** per-screen `onRetry` re-dispatches the load event (`workers_page.dart:132`, `worker_details_page.dart:93`, `invitations_content.dart:54`, maps `place_search_sheet_body.dart:76`).
- **Dead:** `BaseRequestBloc.retry()/RetryEvent`.
Retry UI is offered indiscriminately — including for 404/validation/conflict — because `ServerFailure` is overloaded.

### Approved architecture — Retry Policy Matrix

| Failure | Retry? | Mode | Owner | Max | Backoff | Feedback |
|---|---|---|---|---|---|---|
| `TimeoutFailure` | Yes | auto + manual | interceptor + UI | 2 auto | exp + jitter | silent auto, then inline |
| `OfflineFailure` | Yes | on-reconnect + manual | connectivity tier | ∞ manual | n/a | offline surface |
| `SessionExpiredFailure` (401) | Yes | auto (refresh) | AuthInterceptor | 1 | n/a | invisible → else logout |
| `ServerFailure` (5xx) | Yes | manual | UI (bloc-driven) | manual | n/a | inline/snackbar |
| `RateLimitFailure` (429) | Yes | auto (respect Retry-After) | interceptor | policy | server-driven | inline |
| `ValidationFailure` | No | — | — | — | — | fix-input |
| `ConflictFailure` / `BusinessRuleFailure` | No | — | — | — | — | explain |
| `NotFound` | No | — | — | — | — | empty/redirect |
| `PermissionFailure` / `SecureConnectionFailure` | No | — | — | — | — | explain |
| `CacheFailure` / `LocationFailure` | Yes | manual | UI | manual | n/a | inline retry |
| `UnknownFailure` | Cautious | manual | UI | manual | n/a | inline |

### Known technical debt
- No single retry owner; retry UI not gated by retryability; backoff is nominal (`maxRetries=1` never exercises exponential/jitter); latency can stack (~30s) with no auto-phase feedback; 401 refresh has the queue race.

**✅ Epic 1 update:** **`Failure.isRetryable` now gates the retry UI** (e.g. 404/validation/conflict no longer offer "Retry"). Interceptor uses **exponential backoff + jitter, `maxRetries=2`**. Still open: no single cross-tier retry *owner* (interceptor + connectivity + per-screen remain separate); the queue "race" was assessed as not reproducible (§2).

### Future evolution
- A `RetryPolicy` derived from `Failure.isRetryable` + type, consulted uniformly by the (revived) bloc base and the interceptor tier.

---

## 11. Logging Policy

### Current architecture
- **Two independent console loggers:** `appLogger` (`app_logger.dart`) and a **separate** `Logger` inside `LoggingInterceptor` (`logging_interceptor.dart:10`).
- Only two producers log: `LoggingInterceptor` (per-request) and `AppBlocObserver.onError → appLogger.e`. Repositories, usecases, blocs, and **`ErrorMapper` itself log nothing**.
- `FirebaseObservabilityService` (Crashlytics/Analytics/Perf, `packages/analytics`) is **fully orphaned** — never depended on, initialized, or called. No production observability. No business-event channel.

### Approved architecture — single ownership model
Two owners fan out to typed sinks by policy:
- **`ErrorMapper`** (sees every mapped failure) → routes by type: `UnknownFailure`/5xx → crash; validation/conflict/permission → analytics; offline/timeout → debug-only.
- **Global tier** (`BlocObserver` + zone/framework guards, §12) → crash reporting for anything uncaught.
- One shared logger config; network logs flow through the same owner.
- A dedicated **business-event** channel for successes/domain events (worker invited, branch created).

### Known technical debt
- No single owner; two console loggers; `ErrorMapper` logs nothing; Crashlytics orphaned; no remote sink; no business events; no debug/analytics/crash routing policy.

**✅ Epic 1 update:** **loggers unified** — `LoggingInterceptor` now uses `appLogger`; **`AppBlocObserver.onError` routes to a single `ErrorReporter`** (defaults to `appLogger`, swap in a backend via `ErrorReporter.use`). Still open/gated: remote sink (Crashlytics) pending Firebase config; per-type routing policy and business-event channel deferred with that activation.

### Future evolution
- Wire `FirebaseObservabilityService`; add structured `metadata` (endpoint, status, code) to every logged failure for dashboards.

---

## 12. Global Exception Handling

### Current architecture
- Only `AppBlocObserver` is set (`bootstrap.dart`), logging bloc errors to **console only** (release filter drops < warning).
- **Missing:** `runZonedGuarded`, `FlutterError.onError`, `PlatformDispatcher.onError`, `Isolate` error listener, `ErrorWidget.builder`.
- Firebase never initialized; no crash reporting active. Uncaught async/platform/isolate/build errors are invisible in production.

### Approved architecture
- `runApp` wrapped in `runZonedGuarded`; `FlutterError.onError` + `PlatformDispatcher.onError` + isolate listener all forward to the crash sink.
- Custom `ErrorWidget.builder` for release (no raw red screen).
- `AppBlocObserver.onError` forwards to the crash/analytics owner (§11).

### Known technical debt
- Every global surface except `BlocObserver` is missing; the observability layer exists but is disconnected.

**✅ Epic 1 update:** both apps now `runGuarded` (wraps `runZonedGuarded`) and call `installGlobalErrorHandlers()` — **`FlutterError.onError`, `PlatformDispatcher.onError`, and a release `ErrorWidget.builder`** are installed, all routing to `ErrorReporter`. Still open: **isolate error listener** (skipped — rare/web-incompatible) and **Crashlytics activation** (pending Firebase config; the reporter seam is ready).

### Future evolution
- Release-mode user-facing "something went wrong" fallback screen tied to a captured crash id.

---

## 13. Offline Architecture

### Current architecture
- **Detection:** `ConnectivityServiceImpl` over `connectivity_plus` — any interface ≠ none = online (`connectivity_service_impl.dart:22-24`). Interface-presence, **not reachability**.
- **Pre-emptive block:** `NetworkGuard.execute` short-circuits offline requests → `NoInternetFailure` (`network_guard.dart:12-20`).
- **UI:** `ConnectivityController` + `ConnectivityOfflineGate` **push** `/offline` (`AppNetworkErrorPage`) on drop, pop on restore (preserves nav stack).
- Guard and UI controller are **two independent connectivity reads**.

### Approved architecture
- One reachability-aware connectivity source feeding both the guard and the UI.
- Offline is a **non-blocking banner** for browsable/cached screens; full-screen route reserved for hard-offline flows.
- Requests blocked offline return `OfflineFailure`, retried automatically on reconnect (§10).

### Known technical debt
- Interface-not-reachability (captive portals slip through); guard/UI can momentarily disagree; no cached-content browsing while on `/offline`.

### Future evolution
- Reachability probe (lightweight HEAD/ping) + request queue that flushes on reconnect.

---

## 14. Navigation Conventions

### Current architecture
- `go_router` throughout (`context.go/push/pop`).
- Post-success navigation is inconsistent: `pop()` (adds), `pop(result)` (edit result-threading), `go`/replace (auth/otp).
- `/offline` is pushed (not replaced), so Back returns to prior screen.

### Approved architecture
- **Reads** navigate forward with `push`; **create** flows `pop()` after success and let the source refresh (§15); **edit** flows may `pop(result)` *and* the source still refreshes (never rely solely on the returned value for correctness).
- Auth/session transitions use `go`/replace to reset the stack.
- Modal/overlay flows never leave a blocking dialog on the stack after an outcome (dismiss progress before feedback — as `add_worker_page.dart:98` does).

### Known technical debt
- Mixed post-success navigation patterns; result-threading and event-refresh used interchangeably without a rule.

### Future evolution
- A documented navigation contract per flow type (read/create/edit/destroy/auth).

---

## 15. Refresh Conventions

### Current architecture
Three incompatible strategies, no owner:
- **No refresh** (workers add): `push(add)` un-awaited, no re-fetch on return → staleness risk.
- **Result-threading** (workers edit): `pop(updatedWorker)`; caller merges.
- **Forward navigation** (auth/otp): refresh not applicable.
The built-in `RefreshEvent` (`BaseRequestBloc`) is dead.

### Approved architecture
- After any mutation, the affected read source is refreshed via an **explicit signal** — an event to the owning list bloc (preferred) or an awaited `push` result that triggers a re-fetch.
- Result-threading may optimize UX but must **not** be the sole correctness mechanism.
- Language change / relevant global events invalidate cached reads (the `LocaleChangeBus` hook exists for this — currently unused because `BaseRequestBloc` is unused).

### Known technical debt
- Staleness risk in workers-add; no shared invalidation; `RefreshEvent`/`LocaleChangeBus` auto-refresh dead.

**✅ Epic 1 update:** convention established and applied — a mutation pops `true`; the list's add entry points (`_openAddWorker`/`_openAddBranch`) await the result and dispatch the feature's refresh event. **workers-add and branches-add staleness fixed.** Still open: no repository-level cache; `BaseRequestBloc.RefreshEvent`/`LocaleChangeBus` remain unused.

### Future evolution
- Repository-level cache invalidation so writes transparently refresh reads.

---

## 16. API Contract Conventions

### Current architecture
- Backend is NestJS; **real error envelope** is `{ message: string | string[], error: string, statusCode: number }`.
- Validation (400) returns `message` as an **array**; business conflicts also arrive as **400** (e.g. "Cannot delete the only branch", "Worker still manages one or more branches"). 403 carries prose ("Please verify your account first").
- OpenAPI spec (73 paths, 65 schemas) declares only 400/401/403/404 with **no error body schema**, and **no 409/422/500** documented — the client hand-rolls NestJS assumptions.
- Client infers behavior from **HTTP status + English prose + substring matching**.
- (Separate, open) request-shape mismatches recorded in project memory: `city` vs `cityId`, `isAvailable` vs `status`, manager mapping, `company/schedule` path.

### Approved architecture
- Backend exposes a **stable machine-readable error code** (e.g. `errorCode: "ACCOUNT_UNVERIFIED"`, `"BRANCH_LAST_CANNOT_DELETE"`) on every error, plus properly documented error bodies and correct status usage (409 for conflicts, 422 for validation, 429 for rate limit).
- Client maps **code → `Failure`** deterministically (status as fallback), eliminating prose/substring inference.
- Error codes are additive-only API surface with a documented registry and an "unknown code" graceful fallback.

### Architectural impact of stable error codes
Collapses three fragile inference mechanisms (status, prose, substring) into one deterministic lookup; lets the taxonomy become fully business-shaped; removes HTTP/prose leakage from bloc and UI; fixes localization of server errors (Arabic included); enables aggregation by stable code in telemetry. **Single highest-leverage contract change.**

### Known technical debt
- Multi-message validation loss (first-element-only); conflicts == validation == `ServerFailure(400)`; undocumented 409/422/500; locale-fragile 403 sniffing; open request-shape mismatches.

**✅ Epic 1 update:** **multi-message validation loss fixed** (all messages preserved); conflicts vs validation now distinct types; client handles 409/429 by status. **Request-shape mismatches resolved** (`CreateBranchRequest` sends `cityId`/`availabilityMode`). Still ⛔ backend-gated: the live API returns **no `errorCode`** yet — code→`Failure` mapping and 403 prose-sniffing removal wait on the backend; the client seam preserves any body `errorCode` in `metadata`.

### Future evolution
- Codegen the client error map + DTOs from an OpenAPI spec that documents error bodies and codes.

---

## 17. Consolidated Technical-Debt Register

Priority: **P0** critical · **P1** high · **P2** medium · **P3** nice-to-have.
Status: ✅ resolved · 🟡 partially resolved · ⛔ backend-gated · ⬜ open. (Epic 1, 2026-07-21.)

| # | Area | Debt | Prio | Status |
|---|---|---|---|---|
| D1 | Contract/Network | Validation `message` array → only first kept; becomes `ServerFailure`, not `ValidationFailure` | P0 | ✅ all messages preserved → `ValidationFailure` |
| D2 | Global/Logging | No crash reporting active; observability orphaned; no runZonedGuarded/FlutterError/PlatformDispatcher | P0 | 🟡 global guards + `ErrorReporter` seam shipped; Crashlytics activation pending Firebase config |
| D3 | Mutation/Refresh | No post-write freshness owner; workers-add staleness; `RefreshEvent` dead | P0 | ✅ refresh convention + staleness fixed (`RefreshEvent` still dead) |
| D4 | Retry | No single owner; retry UI ignores retryability; nominal backoff | P0 | 🟡 `isRetryable` gating + backoff/jitter done; single cross-tier owner still open |
| D5 | Boundaries | Business classification inside `ErrorMapper` (403 prose sniffing) | P1 | ⛔ kept as fallback — needs backend error codes |
| D6 | Taxonomy | `ServerFailure` overload; conflated 401/location; missing business types; `ValidationFailure` unproduced | P1 | 🟡 `Validation`/`BusinessRule`/`Conflict`/`RateLimit` + `isRetryable` done; 401/location still conflated; `SessionExpired` deferred |
| D7 | Bloc/UI | Failure object-vs-`String` split; HTTP `code` + raw prose leak to UI; `contains(' ')` heuristic | P1 | 🟡 object split + heuristic resolved; `Failure.code`-as-HTTP still read by `isRetryable`/UI |
| D8 | Design System | Missing generic error/retry/validation-summary/dialog; `_ErrorState` duplicated; snackbar overloaded | P1 | 🟡 `AppErrorState`/`AppValidationSummary`/`showAppErrorSnackbar` + dedup done; `AppErrorDialog`/offline banner open |
| D9 | maps | Parallel error regime; `error.toString()` leaks; hardcoded English messages | P1 | ⬜ open |
| D10 | Network | Refresh-queue race; `SessionManager.logout` not unified with interceptor logout | P1 | 🟡 race assessed not reproducible (single isolate); logout unification open |
| D11 | Dead code | `BaseRequestBloc`, `FailureMapper`, `ApiErrorResponse`, dead `ErrorMessages` keys, unused `packages/domain` repos, `API_GUIDE.md` drift | P2 | 🟡 docs reconciled (blueprint + `API_GUIDE.md` error sections); dead code itself still present |
| D12 | Network/Security | TLS pinning dead scaffolding; connectivity = interface not reachability; no `CancelToken`; `transformTimeout` unretried | P2 | ⬜ open |
| D13 | Success | 4 success-modeling styles; inconsistent feedback; no business-event channel | P2 | ⬜ deferred (high-churn/low-value; services→bloc done under D-outlier) |
| D14 | Contract | Request-shape mismatches (`cityId`, `status`, manager mapping, `company/schedule`) | P2 | 🟡 `cityId`/`status` resolved; manager mapping & `company/schedule` not re-verified |

---

### Change control for this document
- Treat **Approved architecture** subsections as the standard for new features **once ratified by the team**. Until then they are proposals derived from the audits.
- When code and this blueprint disagree, either fix the code or update the blueprint in the same PR — do not let it drift (as `API_GUIDE.md` did).
- **Epic 1 (Error Handling Unification)** implemented the ✅/🟡 items above; see `docs/EPIC_1_ERROR_HANDLING_BACKLOG.md` for per-ticket status.
- Companion docs: `docs/ARCHITECTURE.md` (package/dependency structure), `docs/API_GUIDE.md` (error-mapping & error-message sections reconciled 2026-07-21; kept consistent with §2/§6/§16 here).
