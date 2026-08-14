# SANAD — Repository-Wide Cleanup & Refactoring Roadmap (Audit + Plan)

## Context

The SANAD monorepo has grown to **37 packages** across `apps/sanad_provider`, `apps/sanad_client`, `apps/design_catalog`, and `packages/*`. Rapid feature work has left provable dead files, stale build artifacts, unused/missing localization keys, a placeholder sheet, a dead route constant, and several duplicate implementations. This roadmap is the deliverable of a **read-only audit** (three parallel evidence-cited sweeps: inventory/deps/assets, localization, dead-code/sheets/BLoC/routes). It is **plan-only** — no production code was changed. The goal is aggressive-but-safe cleanup that **preserves all business logic and product behavior**; anything whose usage can't be proven dead is classified **KEEP / manual review**, never deleted.

**Scope decisions (confirmed with the user):**
1. Localization duplicate-key consolidation → **full in-scope phase** (Phase 3).
2. Six externally-unconsumed infra packages (`analytics, notifications, device, utilities, flavors, config`) + `sanad_client` shell → **KEEP / pending integration**, explicitly out of scope for removal.
3. HIGH/CRITICAL categories (storage/cache, route removals, BLoC state/event removal, repo consolidation) → **included as gated late phases** requiring explicit per-item approval before execution.

---

## Repository inventory (summary)

- **Apps:** `sanad_provider` (primary; features in `lib/src/features/*` + `packages/{branches,services,workers,provider_rbac}`), `sanad_client` (**placeholder shell** — 18 files/535 LOC, 9 stub pages), `design_catalog` (internal Widgetbook).
- **Shared packages (consumed):** core, design_system, shared_ui, network, localization, app_assets, app_logger, storage, sheet_navigation, auth, account_settings, contact_verification, document_flow, media, media_upload, asset_picker, otp, permissions, maps, bottom_nav_bar, deep_linking, testing.
- **Unconsumed infra (KEEP / pending integration — decision 2):** analytics, notifications, device, utilities, flavors, config. Evidence: zero external `package:` imports and zero reverse pubspec deps. Most likely pending wiring, not dead — **no removal proposed**; revisit when the team confirms roadmap.
- Root `pubspec.yaml` declares a 43-member Dart workspace (Melos 7); `tools/` (`sanad_tools`) is a standalone CLI, intentionally outside the workspace.

---

## Findings by category (evidence-based)

### A. Stray / dead files — HIGH confidence
| Item | Evidence | Action | Risk |
|---|---|---|---|
| `packages/features/` (14 subdirs) | `git ls-files` = 0 tracked, 0 `.dart` in any `lib/`, not in workspace; contains only `build/`/logs/empty skeletons | **REMOVE** (local dir; superseded by `apps/sanad_provider/packages/*` + `packages/*`) | LOW |
| `firebase-debug.log` (root) | git-tracked, not gitignored, stale (2026-07-30) | **REMOVE** + add to `.gitignore` | LOW |
| `flutter_0N.log` ×10 (various roots) | already gitignored, untracked local | Clear locally (no commit) | LOW |
| `OTP_SHEET_MIGRATION_REPORT.md` (root), `services-feature-audit-and-refactoring-plan.md` (services pkg root) | tracked planning docs in source dirs | **MANUAL REVIEW** → relocate to `docs/` or remove if obsolete | LOW |

### B. Localization (counts: en-US 824 keys, ar-AR 824, perfect parity)
| Category | Count | Evidence | Action |
|---|---|---|---|
| **Used-but-MISSING (bug)** | **20** | entire `settings.legal_documents.*` namespace absent from en-US; used in `legal_documents_page.dart` → users see raw keys | **ADD** EN+AR copy (Phase 2) |
| Unused **and** empty-AR stubs | 6 | `contact_verification.*` + `document_flow.*` (title/empty_title/empty_description) | **REMOVE** |
| Defined-but-unused (conservative) | 74 (incl. the 6 above) | full dotted-key substring scan; 15 dynamic-only keys correctly excluded | **REMOVE after per-key dynamic recheck**; verify `*_coming_soon`/`placeholder_*` scaffolding intent first |
| Dynamic-only reachable (do NOT flag) | 15 | `branches.*.days.{day}`, `branches.{add,edit}_branch.success_dialog_*` via `'$prefix.…'.tr()` | KEEP |
| Duplicate English values | 91 values / 246 keys | e.g. "Cancel" ×10, "Must be between {min} and {max} characters." ×4 | **CONSOLIDATE** (Phase 3) |
| Hardcoded UI strings | 19 | mostly placeholder scaffold pages + `media_upload_grid.dart:142` "Retry all" | Localize the real widgets; scaffold pages lower priority |
| `validation.form.uae_phone_invalid` | present ✓ | confirmed in both locales (line 901) | no action |

### C. Widgets / sheets / dialogs
| Item | Location | Finding | Action | Risk |
|---|---|---|---|---|
| `EditComplianceDocumentsBottomSheet` | organization_settings/.../bottom_sheets | `build()` returns `SizedBox.shrink()`; zero external refs | **REMOVE** | LOW |
| `showWorkerConfirmationSheet` vs `showServiceConfirmationSheet` | workers vs services | near-duplicate wrappers over `AppConfirmationContent` (service's own comment says it "mirrors" workers') | **MERGE** → `showConfirmationSheet` in shared_ui | MED |
| `*_view` state family (`AppEmptyView`, `AppErrorView`, `AppLoadingView`, `AppNoConnectionView`, `AppUnauthorizedView`) | shared_ui/lib/src/states | 0 external refs; superseded by `*_state` family + `AppSkeletonizer` (18 ext) / `AppErrorState` (7 ext) | **INVESTIGATE → REMOVE if confirmed** | MED |
| `headers/` (`AppProfileHeader`, `AppImageHeader`, `AppSearchHeader`), `effects/` (Blur/Parallax/Stretch/ImageZoom/NavSurfaceTransition) | shared_ui | 0 external + 0 intra refs | **INVESTIGATE → REMOVE if confirmed** | MED |
| `AppRadioTile`, `AppTabBar`, `AppCalendarDay`, `AppFillRemainingScrollable`, `AppValidationSummary`, `AppDashedBorder`, `MediaUploadDropZone`, `AppSuccessPopoverIllustration`, catalog previews | design_system / shared_ui | 0 external + 0 intra + 0 catalog refs (some possibly superseded by `AppRadio`/`AppDatePicker`) | **INVESTIGATE** per symbol | MED |
| `AppBottomSheet`/`showAppBottomSheet` vs `AppModalSheet`/`showAppModalSheet` | design_system | two sheet primitives; bottom variant used by only 2 permission dialogs | **INVESTIGATE** consolidation onto modal | MED |
| `*StyleSpec`/`*Tokens` (0 external) | design_system theme | consumed via `context.appColors`/theme extensions — NOT dead | KEEP | — |

### D. Duplication hotspots
| Item | Finding | Class | Action | Risk |
|---|---|---|---|---|
| Initials logic ×4 | `branches/person_initials.dart`, `workers/worker_dto._initials`, `workers/invitation_dto._initials`, `auth/session_manager.initials` — same "≤2 uppercase initials" rule | B | **MERGE** → single `core`/shared helper | MED |
| `DefaultAssetValidator` (asset_picker) vs `MediaUploadValidator` (media_upload) | same PickedAsset count/size/ext/MIME checks; different option+error models (batch/all-errors vs single/first-failure); media_upload already imports asset_picker | B | **INVESTIGATE** — viable but must reconcile two config+error models; may stay separate if not behaviorally equivalent | MED |
| Loaders/progress across design_system + shared_ui (`AppLoadingIndicator`, `AppProgressBar`, `AppProgress`) | overlapping primitives | D | **INVESTIGATE** ownership; likely keep distinct | LOW |

### E. Routes / exports
| Item | Finding | Action | Risk |
|---|---|---|---|
| `RequestsRoutes.list` = `/requests` | dead constant, 0 refs, duplicates the registered `AppRoutes.requests` | **REMOVE** | LOW |
| Barrel exports of any removed symbol | must be pruned alongside removals; check public-API consumers first | prune with removals | LOW |
| Invitation/OTP deep-link routes | reachable via `/invitation/:token` deep link — NOT dead | KEEP (manual review before any route touch) | — |

### F. BLoC events/states (dispatch-site analysis — needs per-bloc confirmation)
| Event (+handler) | Location | Finding | Action | Risk |
|---|---|---|---|---|
| `IdentityHeaderUploadCancelled` (`_onCancelled`) | org_settings/identity_header | never dispatched (prod 0 / test 0) | **INVESTIGATE** (upload-cancel UI may be unshipped) | HIGH |
| `AddWorkerResetEvent` (`_onReset`) | workers/add_worker | never dispatched | **INVESTIGATE** | HIGH |
| `IdentityHeaderUploadRetried`, `RoleUpsertedInListEvent`, `RemoveRoleRequestedEvent` | identity_header / provider_rbac | dispatched **only in tests** | **INVESTIGATE** (affordance planned vs dead) | HIGH |

### G. Dependencies / assets
| Item | Finding | Action | Risk |
|---|---|---|---|
| `provider` (^6.1.5) in both apps | bloc-based app; suspect unused | **INVESTIGATE** — remove only if no `ChangeNotifierProvider`/`context.watch` | MED |
| `flutter_hooks`, `path_provider`, `hydrated_bloc` (apps) | may be transitive-only-listed | **MANUAL REVIEW** direct usage | MED |
| Empty declared asset dirs: `app_assets` `icons/`, `animations/`, `images/onboarding/` | declared, empty | **MANUAL REVIEW** (drop declaration or keep as placeholder) | LOW |
| `registration_shutter.svg`, `registration_gallery.svg` | on disk, no `AppSvgs` constant, 0 refs | **MANUAL REVIEW** (staged for doc-capture flow; do not auto-delete) | LOW |
| Build/lint/plugin deps (`very_good_analysis`, `flutter_launcher_icons/native_splash`, `firebase_core`, `easy_localization`, test infra) | never appear as direct imports by design | KEEP | — |

### H. KEEP-reserved (public API — do NOT remove)
`PhoneValidator`, `EmiratesIdValidator`, `DateValidators` in `packages/core` — 0 prod call-sites but tested, exported, intentionally reserved for not-yet-wired flows (Emirates-ID entry, DOB/expiry, non-UAE phone). Removing them would be a behavior/API decision, not a dead-code fix.

### I. Categories needing execution-time sweeps (methodology, not yet enumerated)
Tests (obsolete/duplicate fixtures, coverage gaps for newly-shared components), architecture ownership corrections (design_system vs shared_ui vs core placement), simplification (redundant wrappers/copyWith/async), network/DTO duplication, cache/storage keys. Each has a grep/analyze recipe below and is swept during its phase — findings are documented, not pre-asserted.

---

## Master matrix (seed — extended during execution)

| Item | Location | Finding | Evidence | Action | Risk | Depends on |
|---|---|---|---|---|---|---|
| `packages/features/` | repo | stale build junk | 0 tracked/0 dart | REMOVE | LOW | — |
| `firebase-debug.log` | root | committed log | git-tracked | REMOVE + gitignore | LOW | — |
| `settings.legal_documents.*` (20) | en-US.json | missing → raw keys shown | grep=0 | ADD EN+AR | MED | copy authored |
| 6 empty+unused loc stubs | both locales | dead + untranslated | scan | REMOVE | LOW | — |
| 68 other unused loc keys | both locales | no static/dynamic ref | scan | REMOVE (recheck each) | MED | dynamic recheck |
| 246 duplicate-value keys | both locales | consolidatable | value-invert | CONSOLIDATE | MED | Phase 2 done |
| `EditComplianceDocumentsBottomSheet` | org_settings | SizedBox.shrink stub | grep | REMOVE | LOW | — |
| `RequestsRoutes.list` | requests/routes | dead constant | grep=0 | REMOVE | LOW | — |
| worker+service confirm sheets | workers/services | duplicate wrappers | code comment | MERGE→shared_ui | MED | tests |
| initials ×4 | branches/workers/auth | duplicate rule | grep | MERGE→core helper | MED | tests |
| shared_ui `*_view`/`headers`/`effects` | shared_ui | 0 refs | grep | INVESTIGATE→REMOVE | MED | export prune |
| `provider` dep | both apps | suspect unused | grep | INVESTIGATE→REMOVE | MED | verify CI |
| dead/test-only BLoC events | 5 blocs | no prod dispatch | grep | INVESTIGATE (gated) | HIGH | manual confirm |
| `PhoneValidator`/`EmiratesIdValidator`/`DateValidators` | core | reserved API | 0 prod | KEEP-reserved | — | — |

---

## Phased execution plan

**Phase 0 — Baseline & safety net.** Commit this doc to `docs/cleanup-audit.md`. Capture green baselines: `fvm dart analyze` + `fvm flutter test` per package; confirm clean tree. Add `firebase-debug.log` to `.gitignore`. Each later phase is its own branch/commit, reversible.

**Phase 1 — Zero-risk file hygiene (LOW).** Remove `packages/features/`, committed `firebase-debug.log`, local `flutter_0N.log`; relocate/verify the two stray docs. Verify: tree builds, `git diff --check`.

**Phase 2 — Localization correctness (MED, highest user value).**
- 2a: add the 20 `settings.legal_documents.*` keys (EN + AR copy) — fixes visible raw-key bug.
- 2b: delete the 6 unused+empty stubs.
- 2c: delete the remaining ~68 unused keys after re-running the dynamic-key recheck per key; keep any confirmed `*_coming_soon`/`placeholder_*` scaffolding.
- 2d: localize the real hardcoded widgets (e.g. `media_upload_grid` "Retry all").
- Verify: key-parity script (EN==AR count), `flutter test`, grep confirms no remaining used-but-missing.

**Phase 3 — Localization duplicate-key consolidation (MED, wide diff — in scope per decision 1).** Introduce shared `common.*` (cancel/save/delete/confirm/retry/add/edit/search/continue/okay) and `validation.*` (shared length/required messages) namespaces; migrate call sites feature-by-feature to the shared keys; delete the ~150 redundant keys. Behavior-neutral (identical strings). Verify **per feature**: rendered text unchanged, feature tests green, parity script passes.

**Phase 4 — Dead widgets / sheets / dialogs (LOW–MED).** Remove `EditComplianceDocumentsBottomSheet`. For each INVESTIGATE widget (shared_ui `*_view`/`headers`/`effects`; design_system `AppRadioTile`/`AppTabBar`/`AppCalendarDay`/`AppFillRemainingScrollable`/`AppValidationSummary`/`AppDashedBorder`/`MediaUploadDropZone`/`AppSuccessPopoverIllustration`/previews): run the confirmation recipe (grep symbol across apps+packages+catalog, check exports/DI/dynamic) → remove only if 0 reachable refs, pruning barrel exports together. Verify: `dart analyze` (unused-export lints), `flutter test`, design_catalog builds.

**Phase 5 — Duplicate consolidation (MED).** MERGE the two confirmation sheets → `showConfirmationSheet` in shared_ui; MERGE the 4× initials logic → one `core`/shared helper (base on `person_initials.dart`), updating all call sites. INVESTIGATE `AppBottomSheet`→`AppModalSheet` and asset_picker/media_upload validators (only merge if behaviorally equivalent; else document as intentionally-separate). Verify: affected widget tests, visual smoke.

**Phase 6 — Exports & dead route constant (LOW).** Remove `RequestsRoutes.list`; sweep barrel files for exports of now-removed symbols; confirm no external consumer breaks. Verify: `dart analyze`, dependent packages compile.

**Phase 7 — Dependency & asset hygiene (MED, gated).** Confirm+remove `provider` if unused; verify `flutter_hooks`/`path_provider`/`hydrated_bloc`; resolve empty asset-dir declarations. Verify: `flutter pub get`, full `flutter test`, app boots.

**Phase 8 — GATED HIGH/CRITICAL (explicit per-item approval — decision 3).**
- Dead/test-only BLoC events + handlers (`IdentityHeaderUploadCancelled`, `AddWorkerResetEvent`, `IdentityHeaderUploadRetried`, `RoleUpsertedInListEvent`, `RemoveRoleRequestedEvent`): confirm unshipped-planned (KEEP) vs dead (REMOVE) with the team. **HIGH.**
- Route removals beyond the dead constant; repository/use-case consolidation. **HIGH.**
- Storage/cache/Hive-box/persisted-model changes: **CRITICAL — data-loss risk**; deep manual review, migration-aware, not part of routine cleanup.
- Confirm KEEP-reserved validators are untouched.
Nothing in this phase runs without a second sign-off.

**Phase 9 — Final verification.** Full `fvm dart analyze` + `fvm flutter test` across all packages, `git diff --check`, and manual smoke of every touched flow (settings, workers, branches, services, RBAC, auth). Confirm the Definition of Done.

---

## Verification strategy (every phase)
- Static: `fvm dart analyze <pkg>` (zero new lints; unused-import/element lints catch dead code), targeted grep re-confirmation of each removal.
- Tests: `fvm flutter test <pkg>` for every touched package; core (140) + design_system stay green.
- Localization: a small key-parity + used-vs-defined script re-run after Phases 2–3.
- Build: `apps/sanad_provider` and `apps/design_catalog` compile; `flutter pub get` clean after dep changes.
- Repo: `git diff --check`; each phase is an isolated, revertible commit.

## Definition of done
No proven-dead production code, widgets, sheets, dialogs, routes, or exports remain; no used-but-missing or provably-unused localization keys; duplicate helpers/components consolidated or documented as intentionally separate; no unnecessary dependencies; business behavior, auth/OTP, persistence, and Clean-Architecture boundaries preserved; all tests green. Uncertain items remain KEEP / manual-review, never deleted.

---

## Execution log

Progress against this roadmap is tracked phase-by-phase as execution proceeds. See git history for the corresponding commits.
