# Epic 1 — Error Handling Unification (Backlog)

> **Type:** Planning artifact.
> **Source of truth:** [docs/ARCHITECTURE_BLUEPRINT.md](ARCHITECTURE_BLUEPRINT.md) (sections cited as *BP §n*)
> and its Technical-Debt Register (items cited as *Dn*).
> **Status:** Sprints 1–4 implemented (2026-07-21). Estimates are relative (S ≈ ≤1d, M ≈ 2–3d, L ≈ 4–5d, XL ≈ >1 sprint-week).

---

## Implementation status (updated 2026-07-21)

Legend: ✅ done · 🟡 partial · ⛔ backend-gated · ⬜ deferred.

| Ticket | Summary | Status |
|---|---|---|
| EH-S1-01 | ValidationFailure (all messages) | ✅ |
| EH-S1-02 | Failure-object state migration (auth/otp/forgot_password) | ✅ |
| EH-S1-03 | Failure Resolver (`FailureLocalizer`) + heuristic removal | ✅ |
| EH-S1-04 | Error components (`AppErrorState`/`AppValidationSummary`/`showAppErrorSnackbar`) | 🟡 `AppErrorDialog` deferred (no consumer) |
| EH-S2-01 | Retry Policy (`isRetryable` gating, backoff+jitter, maxRetries=2) | 🟡 single cross-tier owner still open; queue-race assessed not reproducible |
| EH-S2-02 | Logging (unified loggers, `ErrorReporter`) | 🟡 business-event channel deferred with Firebase |
| EH-S2-03 | Global guards + crash seam | 🟡 guards installed; **Crashlytics activation ⛔ pending Firebase config**; isolate listener skipped |
| EH-S3-01 | Success Lifecycle (services→`Cubit`; feedback/message policy) | 🟡 full success-*state* unification ⬜ deferred |
| EH-S3-02 | Refresh Lifecycle (staleness fixed) | ✅ |
| EH-S4-01 | Backend stable error codes | ⛔ backend team — API still returns no `errorCode` |
| EH-S4-02 | Client code→Failure + business taxonomy (`Conflict`/`BusinessRule`/`RateLimit`) | 🟡 status-mapping done; code→Failure & 403-sniffing removal gated on EH-S4-01 |
| EH-S4-03 | Request-shape mismatches | 🟡 `cityId`/`status` resolved; manager mapping & `company/schedule` not re-verified |

Not-yet-scheduled cleanup remains open: **D9** (maps error regime), **D11** (dead code: `BaseRequestBloc`/`FailureMapper`/`ApiErrorResponse`/unused `packages/domain`/`API_GUIDE.md` drift), **D12** (TLS pinning, reachability, `CancelToken`). Consider a **Sprint 5 — Cleanup & Hardening**.

---

## Epic Overview

**Goal.** Make error handling **contractual, consistent, and observable** end-to-end: one failure taxonomy, one message resolver, one retry policy, one logging/crash owner, one success/refresh convention, and (with backend) stable error codes.

**Problem statement (from the audits).** The data/mapping spine is clean, but four vacuums cause inconsistency: (1) `ServerFailure` overload + un-produced `ValidationFailure`; (2) no central `Failure→message` resolver (brittle `contains(' ')` heuristic); (3) no single retry/logging owner and no active crash reporting; (4) no owner for the "after" of an operation (success feedback + list refresh).

**Definition of Done (epic).**
- Every backend error deterministically becomes a business-shaped `Failure` (no prose/substring inference in app code).
- One resolver turns any `Failure` into a localized string; the `contains(' ')` heuristic is deleted.
- Shared DS error/retry/validation components; zero duplicated `_ErrorState`.
- One retry policy driven by `Failure.isRetryable`; one logging owner; Crashlytics live with global guards.
- One success representation + one post-mutation refresh convention; workers-add staleness fixed.
- Backend exposes stable error codes; client maps code→`Failure`.

**Success metrics.**
- 0 occurrences of raw server prose shown to users (all via resolver keys).
- 0 duplicated error-state widgets; 0 `contains(' ')` heuristics.
- Crash-free-sessions metric visible in Crashlytics; uncaught-error capture > 0 in staging tests.
- 100% of features carry a `Failure` object in state (no `String` flattening).

---

## Cross-Sprint Dependency Graph

```
Sprint 1  Taxonomy (ValidationFailure, isRetryable seed) ──┐
          Failure-object state migration ──┐               │
          Failure Resolver ◄───────────────┘               │
          Error Components ◄── Resolver                     │
                                                            ▼
Sprint 2  Retry Policy ◄── isRetryable (S1 taxonomy)
          Logging owner ◄── ErrorMapper hook
          Crashlytics + global guards ◄── Logging sinks
                                                            ▼
Sprint 3  Success Lifecycle ◄── Failure-object states (S1)
          Refresh Lifecycle ◄── Success representation
                                                            ▼
Sprint 4  API Error Codes ◄── Taxonomy (S1) ── (BACKEND + client codegen)
```

**Rule:** each sprint depends on the prior. The one hard external dependency is **Sprint 4 (backend team)**; it can start discovery in parallel but lands last because the client-side taxonomy must be stable first.

---

## Sprint 1 — Foundations (Taxonomy · Resolver · Components)

**Theme:** establish the vocabulary and the presentation primitives everything else builds on.
**Debt addressed:** D1, D6 (partial), D7, D8, D11 (partial).

### EH-S1-01 · ValidationFailure (+ business-400 disambiguation)
- **Scope.** Produce a real `ValidationFailure` from the NestJS 400 envelope, preserving **all** messages (backend returns `message` as a `string[]`). Distinguish validation vs. business-conflict 400s. Seed `ConflictFailure`/`BusinessRuleFailure` if trivial; otherwise defer full set to S4.
- **Rationale (D1/D6/BP §6, §16).** Today 400s collapse to `ServerFailure` and only the first message survives (`_flattenField`, `error_mapper.dart:187`); `ValidationFailure` is defined but never constructed.
- **Affected.** `packages/core/.../failures/failure.dart`, `failure_extensions.dart`, `packages/network/.../client/error_mapper.dart`, `packages/network/.../models/api_error_response.dart` (revive or delete), tests in `packages/network/test`, `packages/core/test`.
- **Acceptance criteria.**
  - A 400 with `message: string[]` yields `ValidationFailure` carrying every message (and field map when derivable).
  - No validation message is dropped; `_flattenField`'s first-only behavior no longer applies to validation.
  - `FailureKindX.isValidation` returns true for these; unit tests cover single-string and array bodies.
  - Business-rule 400s (e.g. "Cannot delete the only branch") are not mislabeled as validation.
- **Dependencies.** None (leaf). **Blocks** Resolver, Retry, S4.
- **Effort.** M · **Risk.** Med (mapper is central; needs strong tests).

### EH-S1-02 · Failure-object state migration
- **Scope.** Migrate blocs/states that flatten `Failure`→`String` (auth, otp, forgot_password) to carry the **`Failure` object**, matching branches/workers/maps.
- **Rationale (D7/BP §4, §7).** Resolver and retry gating are impossible where type/code/metadata were discarded; auth already re-classifies `UnverifiedUserFailure` in-bloc to compensate (`auth_bloc.dart:64`).
- **Affected.** `packages/features/auth/.../bloc/auth/*`, `packages/features/otp/.../bloc/*`, `packages/features/forgot_password/.../bloc/*` and their pages.
- **Acceptance criteria.**
  - All failure states expose a `Failure` field (no `String message` failure fields remain).
  - auth's manual `UnverifiedUserFailure` special-case still works via the object.
  - Existing bloc tests updated/green; no behavior regression in shown messages.
- **Dependencies.** Soft-depends on EH-S1-01 (taxonomy shape). **Blocks** EH-S1-03 effectiveness, S3.
- **Effort.** M · **Risk.** Med (touches auth surface).

### EH-S1-03 · Failure Resolver
- **Scope.** One UI-layer resolver: `Failure → localized string`, keyed off failure **type** (via `FailureKindX`), not string inspection. Retire the `contains(' ') ? raw : .tr()` heuristic. Raw server prose kept only in `metadata`.
- **Rationale (D7/BP §5, §7).** No central resolver exists; the heuristic is duplicated in `branches_page.dart:66`, `branch_details_page.dart:273`, workers pages; auth/otp `.tr()` unconditionally (leaks English).
- **Affected.** New resolver (likely `packages/core` or a presentation-shared package), `packages/localization` (ensure keys), all feature pages currently resolving messages.
- **Acceptance criteria.**
  - Single entry point maps every `Failure` subtype to a localized key (en + ar).
  - `contains(' ')` heuristic removed from all call sites.
  - Dead localized keys (`errors.unauthorized/not_found/bad_request/invalid_credentials`) are either wired or removed.
  - No raw server English reaches the UI (verified for 401/404/400 paths).
- **Dependencies.** EH-S1-01, EH-S1-02. **Blocks** EH-S1-04, S3 feedback.
- **Effort.** M · **Risk.** Low-Med.

### EH-S1-04 · Error Components (Design System)
- **Scope.** Add failure-agnostic DS primitives: `AppErrorState({title,message,onRetry})`, `AppErrorDialog`, `AppValidationSummary`; optionally `AppOfflineBanner`. Replace duplicated private `_ErrorState`. Differentiate error vs. success snackbar styling.
- **Rationale (D8/BP §5).** `_ErrorState` duplicated in `branches_page.dart:292`, `workers_page.dart:232`, `invitations_content.dart:122`; network widgets reused for non-network errors; snackbar overloaded.
- **Affected.** `packages/design_system/.../shared_ui/*`, `components/app_snackbar.dart`, consuming feature pages.
- **Acceptance criteria.**
  - DS components accept **strings + callbacks only** (no `Failure`, no i18n keys).
  - All private `_ErrorState` widgets deleted and replaced by `AppErrorState`.
  - Non-network failures (500/timeout) use generic error copy, not network illustration.
  - Error snackbars visually distinct from neutral/success.
- **Dependencies.** EH-S1-03 (features pass resolved strings). 
- **Effort.** L · **Risk.** Low.

**Sprint 1 exit:** deterministic validation failures, `Failure` objects everywhere, one resolver, shared error UI.

---

## Sprint 2 — Reliability & Observability (Retry · Logging · Crashlytics)

**Theme:** one retry owner, one logging owner, active crash reporting.
**Debt addressed:** D2, D4, D5, D10 (partial), D12 (global surfaces).

### EH-S2-01 · Retry Policy
- **Scope.** Add `bool get isRetryable` (+ mode) to the taxonomy; implement one `RetryPolicy` consulted by the interceptor tier and the UI. Gate retry affordances by retryability. Introduce real backoff (exponential + jitter, max attempts > 1). Fix the 401 refresh-queue race.
- **Rationale (D4/D10/BP §10).** Three uncoordinated retry owners; retry UI offered for non-retryable failures; `maxRetries=1` never exercises backoff; refresh-queue can hang.
- **Affected.** `packages/core/.../failures/*`, `packages/network/.../interceptors/retry_on_timeout_interceptor.dart`, `auth_interceptor.dart`, feature retry call sites, DS `AppErrorState` (show/hide retry).
- **Acceptance criteria.**
  - `isRetryable` implemented per the BP §10 matrix; non-retryable failures never render a retry button.
  - Timeout retries use exponential backoff + jitter with a configurable max.
  - Refresh-queue race fixed (no request hangs on the resolve/reset window); regression test added.
  - Dead `BaseRequestBloc.retry`/`RetryEvent` either adopted or removed.
- **Dependencies.** EH-S1-01 (taxonomy). **Effort.** L · **Risk.** Med (interceptor concurrency).

### EH-S2-02 · Logging (single owner)
- **Scope.** One logging ownership model: log at the `ErrorMapper` choke point + the global tier; route by type to sinks (debug / analytics / crash). Unify the two console loggers (`appLogger` vs `LoggingInterceptor`'s own `Logger`). Add a business-event channel.
- **Rationale (D5/BP §11).** Two independent loggers; `ErrorMapper` logs nothing; no business-event channel; no routing policy.
- **Affected.** `packages/app_logger/*`, `packages/network/.../interceptors/logging_interceptor.dart`, `error_mapper.dart` (log hook), `app_bloc_observer.dart`.
- **Acceptance criteria.**
  - Single shared logger config; network + app logs flow through it.
  - Every mapped failure is logged once with structured metadata (endpoint, status, code) — no double logging.
  - Debug/analytics/crash routing policy documented and implemented (stub sinks OK until EH-S2-03).
- **Dependencies.** Soft: EH-S1-01. **Blocks/pairs with** EH-S2-03. **Effort.** M · **Risk.** Low-Med.

### EH-S2-03 · Crashlytics + Global Guards
- **Scope.** Wire the orphaned `FirebaseObservabilityService`: `Firebase.initializeApp`, register in DI, `initialize()`. Add global guards: `runZonedGuarded`, `FlutterError.onError`, `PlatformDispatcher.onError`, isolate listener, release `ErrorWidget.builder`. Forward `AppBlocObserver.onError` → crash sink.
- **Rationale (D2/D12/BP §11, §12).** No crash reporting active; observability layer fully orphaned; every global surface except `BlocObserver` missing.
- **Affected.** `apps/sanad_provider/.../bootstrap/bootstrap.dart`, `apps/sanad_client/.../bootstrap.dart`, app DI, `packages/analytics/*` wiring, app `pubspec.yaml` deps.
- **Acceptance criteria.**
  - Uncaught async, platform, isolate, and framework errors are captured and reach Crashlytics in staging (verified with induced errors).
  - Release builds show a branded fallback (no raw red screen) with a crash id.
  - Crash-free-sessions metric visible in the Firebase console.
- **Dependencies.** EH-S2-02 (sink contract). **Effort.** L · **Risk.** Med (Firebase setup, per-flavor config).

**Sprint 2 exit:** semantic retry, unified logging, live crash reporting with full global capture.

---

## Sprint 3 — Operation Outcomes (Success · Refresh)

**Theme:** own the "after" of every operation.
**Debt addressed:** D3, D13, plus BP §8, §9, §14, §15.

### EH-S3-01 · Success Lifecycle
- **Scope.** One canonical success representation (typed success state or shared status enum) across features; consistent feedback policy (mutations confirm; reads don't); success messages as keys resolved centrally. Bring services into the bloc pattern (remove direct `sl<UseCase>()` widget call).
- **Rationale (D13/BP §8).** 4 success-modeling styles; inconsistent/absent feedback; success message stored as raw `String`; services bypasses blocs.
- **Affected.** feature blocs/states (auth, otp, forgot_password, branches, workers, services), `packages/features/services/.../select_service_action_sheet.dart`, resolver (success keys).
- **Acceptance criteria.**
  - One success representation used by all audited features.
  - Feedback policy applied consistently (documented in BP §8/§14).
  - services routes through a bloc; no widget calls a usecase directly.
- **Dependencies.** EH-S1-02, EH-S1-03. **Effort.** L · **Risk.** Med.

### EH-S3-02 · Refresh Lifecycle
- **Scope.** One post-mutation refresh convention: an explicit invalidation signal to the owning list bloc (result-threading may optimize UX but is not the sole correctness path). Fix workers-add staleness. Decide fate of dead `RefreshEvent`/`LocaleChangeBus` auto-refresh.
- **Rationale (D3/BP §9, §15).** Three incompatible refresh strategies; workers-add `push` un-awaited with no re-fetch (`workers_page.dart:201,224`) → stale list.
- **Affected.** `packages/features/workers/.../workers_page.dart`, add/edit worker pages, `packages/features/branches/*` equivalents, `packages/core/.../blocs/base_request_bloc.dart` (adopt or remove).
- **Acceptance criteria.**
  - After any create/edit/delete, the source list reflects the change without manual re-entry.
  - workers-add staleness reproduced pre-fix and verified fixed.
  - Single documented refresh convention; result-threading not relied on for correctness.
- **Dependencies.** EH-S3-01. **Effort.** M · **Risk.** Med.

**Sprint 3 exit:** consistent success feedback and guaranteed post-write freshness.

---

## Sprint 4 — Contract (API Error Codes)

**Theme:** make error handling contractual, not heuristic. **Cross-team (backend + mobile).**
**Debt addressed:** D1 (fully), D6 (fully), D14, BP §16.

### EH-S4-01 · Backend stable error codes (backend-owned, mobile-partnered)
- **Scope.** Backend exposes a stable `errorCode` on every error, documents error bodies in OpenAPI, and uses correct status codes (409 conflict, 422 validation, 429 rate limit). Additive-only registry + "unknown code" fallback.
- **Rationale (BP §16).** Highest-leverage contract change; collapses status+prose+substring inference into one lookup.
- **Acceptance criteria.**
  - OpenAPI documents error bodies and codes for all error statuses.
  - A published error-code registry exists; codes are additive-only.
- **Dependencies.** None (backend). Start discovery in parallel with S1. **Effort.** XL (backend). **Risk.** High (cross-team).

### EH-S4-02 · Client code→Failure mapping + full taxonomy
- **Scope.** Map `errorCode → Failure` deterministically (status fallback for unknown codes). Complete the business taxonomy (`ConflictFailure`, `SessionExpiredFailure`, `BusinessRuleFailure`, `RateLimitFailure`, split `Location*`, rename `NoInternet→Offline`). Remove 403 prose sniffing. Make intermediate `Failure` subtypes `final`/`sealed`.
- **Rationale (D6/BP §6, §16).** Removes locale-fragile inference; taxonomy becomes fully business-shaped; `sealed` finally meaningful.
- **Affected.** `packages/network/.../error_mapper.dart`, `packages/core/.../failures/*`, resolver keys, maps failure subtypes.
- **Acceptance criteria.**
  - `ErrorMapper` no longer inspects English prose; 403 classification is code-driven.
  - Full taxonomy in place; exhaustiveness enforced by `sealed`.
  - Unknown codes degrade gracefully to status-based mapping.
- **Dependencies.** EH-S4-01, EH-S1-01. **Effort.** L · **Risk.** Med.

### EH-S4-03 · Resolve open request-shape mismatches (D14)
- **Scope.** Address the pre-existing request-body mismatches recorded in project memory (`city`→`cityId`, `isAvailable`→`status`, manager mapping, `company/schedule`→`profile/availability`).
- **Rationale (D14).** Orthogonal to error handling but naturally batched with the contract sprint.
- **Acceptance criteria.** Branch create/update send correct fields; no silent 400s from shape drift.
- **Dependencies.** EH-S4-01 (spec confirmation). **Effort.** M · **Risk.** Med.

**Sprint 4 exit:** contractual, code-driven error handling; taxonomy complete and closed.

---

## Sequencing Rationale

1. **S1 first** because taxonomy + resolver + components are the shared vocabulary; retry gating, logging routing, and success feedback all consume them. Building retry/logging before the taxonomy would bake in the current overloads.
2. **S2 before S3** because success/refresh feedback should flow through the unified logging/observability tier (business events) and rely on stable states from S1.
3. **S3 before S4** because success/refresh are client-only and unblock UX value without waiting on backend.
4. **S4 last** because it has the hard external (backend) dependency; it *finalizes* the taxonomy that S1 seeds. Its discovery (EH-S4-01) can begin in parallel during S1–S3.

**Parallelization notes.** Within S1: EH-S1-01 and EH-S1-04 (component shells) can start together; EH-S1-03 gates on -01/-02; -04 integration gates on -03. Backend discovery (EH-S4-01) runs as a background track from day one.

**Risk register (top).** ErrorMapper centrality (S1/S4) — mitigate with exhaustive tests before/after. Interceptor concurrency (S2 retry/refresh) — add race regression tests. Firebase per-flavor setup (S2) — verify on all flavors. Cross-team contract (S4) — start early, define fallback.

---

## Traceability — sprint items → blueprint debt

| Sprint item | Tickets | Debt (BP §17) |
|---|---|---|
| ValidationFailure | EH-S1-01 | D1, D6 (partial) |
| Failure Resolver | EH-S1-02, EH-S1-03 | D7 |
| Error Components | EH-S1-04 | D8, D11 (partial) |
| Retry Policy | EH-S2-01 | D4, D10 (partial) |
| Logging | EH-S2-02 | D5 |
| Crashlytics | EH-S2-03 | D2, D12 (global) |
| Success Lifecycle | EH-S3-01 | D13 |
| Refresh Lifecycle | EH-S3-02 | D3 |
| API Error Codes | EH-S4-01, EH-S4-02, EH-S4-03 | D1 (full), D6 (full), D14, D12 (pinning/connectivity remain) |

**Not yet scheduled (from D-register):** D9 (maps parallel error regime — fold into S4-02 taxonomy work or a follow-up), D11 remainder (dead-code cleanup: `FailureMapper`, unused `packages/domain` repos, `API_GUIDE.md` drift), D12 remainder (TLS pinning decision, reachability, `CancelToken`). Recommend a **Sprint 5 "Cleanup & Hardening"** or fold into earlier sprints as capacity allows.

---

*This backlog is documentation only. No code has been modified. Await team ratification before starting EH-S1-01.*
