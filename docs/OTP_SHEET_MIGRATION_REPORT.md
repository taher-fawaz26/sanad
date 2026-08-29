# OTP + Sheet Navigation Migration - Final Report

> **Superseded — historical record only.**
>
> This report predates *two* later refactors: the 2026 Auth backend-contract
> change, and the 2026-08 OTP consolidation. Do not use it for current
> architecture, class names, or paths.
>
> What changed since: `packages/otp` now owns a probe-then-send state machine
> driven by the backend's `resend-info` contract; `OtpVerifier` gained
> `resendCode()` and `cooldown()`; `OtpVerificationView` was replaced by the
> canonical `OtpView` (plus `OtpHost`); auth, account deletion and the worker
> invitation all moved onto it; and the four duplicated contact sheets
> collapsed into one `ContactChangeSheet`. `AuthOtpVerifier`,
> `RequestEmailOtpUseCase`, `VerifyEmailOtpUseCase` and `AuthValidateEmailEvent`
> named below no longer exist.
>
> **Current documentation: [`features/otp.md`](features/otp.md).**
>
> The sheet-navigation half of this report remains an accurate point-in-time
> record of that migration.

## 1. Migrated features

| Feature | Before | After |
|---|---|---|
| Auth email login/signup OTP | `EmailOtpPage` (HookWidget, hand-rolled `Timer.periodic`, dispatched `AuthVerifyOtpEvent`/`AuthRequestOtpEvent` to `AuthBloc`) | Thin wrapper calling `OtpFlow.start` with a new `AuthOtpVerifier` |
| Invitation OTP (demo flow) | `InvitationOtpPage` (mocked `Future.delayed`, local `OtpUiCubit`) | Thin wrapper calling `OtpFlow.start` with `CallbackOtpVerifier` |
| Organization Settings → Edit Contact Info | Plain `showAppBottomSheet`, no verification, no persistence | `SheetNavigator`-hosted sheet; changing the email now runs the shared OTP flow (`OtpFlowConfig.email`, `purpose: changeEmail`) before the sheet returns — the reference "General Settings → Edit Email → OTP → Success → return edited value" flow |
| Settings menu sheet, edit-category, edit-identity sheets (org settings) | `showAppBottomSheet` / raw `showModalBottomSheet` | `SheetNavigator.push` |
| Branches: manager picker, add-custom-day, assign-branch, branch-actions, branch-search, coverage-area search | raw `showModalBottomSheet` / `showAppBottomSheet` / `showAppModalSheet` | `SheetNavigator.push` |
| Workers: action-confirmation, invitation-actions, worker-actions, worker-search | `showAppBottomSheet` / `showAppModalSheet` | `SheetNavigator.push` |
| Maps: city picker, location-picker sheet, map-area picker (×2), map-location picker | raw `showModalBottomSheet` / `showAppModalSheet` / `showAppBottomSheet` | `SheetNavigator.push` |
| Media actions sheet | `showAppBottomSheet` | `SheetNavigator.push` |
| Asset source sheet | raw `showModalBottomSheet` | `SheetNavigator.push` |

## 2. Removed legacy code

- `AuthBloc`: `AuthVerifyOtpEvent`, `AuthOtpVerifyLoadingState`, `AuthOtpVerifyFailureState`, `_verifyOtp` handler, and the `VerifyEmailOtpUseCase` constructor param (the use case itself is still registered in DI — `AuthOtpVerifier` calls it directly now).
- `EmailOtpPage`'s local `Timer.periodic` countdown and manual OTP field wiring.
- `InvitationOtpPage`'s local `OtpUiCubit` usage and mocked `Future.delayed` verification.
- Every raw `showModalBottomSheet` call site outside `design_system`'s own helper implementations (confirmed by a repo-wide grep — zero remain).
- 29 orphaned OTP localization keys across `auth.*`, `invitation.otp_*`, `forgot_password.*`, and `registration.otp_*` in both `en-US.json` and `ar-AR.json` — dead strings for OTP UI that either got replaced by the new `otp.*` namespace or, for `registration`/`forgot_password`, were never wired to any code at all (including a stale "5-digit code" string that contradicted the backend's actual 6-digit contract).

## 3. Deleted / rebuilt files

- Rebuilt from an empty build-artifact shell: `packages/features/otp/` (had no `pubspec.yaml`/`lib/` before this work, despite being reserved in `dep_rules.yaml`).
- No feature files were deleted outright — `EmailOtpPage` and `InvitationOtpPage` were gutted and rewritten in place (same public constructor signatures, so call sites in `auth_shell.dart`/`invitation_module.dart` needed no changes).

## 4. New public APIs

**`packages/sheet_navigation`** (new infra package, tier 3):
`SheetNavigator.push/replace/pop/canPop`, `showSheet`, `ModalSheetRoute<T>`, `SheetRouteSettings`, `SheetScaffold`, `SheetDragController`, `SheetSnap`, `SheetTransitions`. Full API reference in `packages/sheet_navigation/README.md`.

**`packages/features/otp`** (rebuilt feature package, tier 3):
`OtpFlow.start<T>`, `OtpFlowConfig<T>` (+ `.email`/`.phone` factories), `OtpVerifier<T>`, `CallbackOtpVerifier<T>`, `OtpResult<T>` (`OtpVerified`/`OtpCancelled`/`OtpExpired`/`OtpFailed`), `OtpDelivery`, `OtpChannel`, `OtpPurpose`. Full API reference in `packages/features/otp/README.md`.

**`AuthOtpVerifier`** (`packages/features/auth/lib/src/domain/verifiers/auth_otp_verifier.dart`) — the reference adapter wiring `otp` to a real backend; owns the post-verify session-start/status-notifier side effects that used to live in `AuthBloc`.

## 5. Architecture changes

- `dep_rules.yaml`: `otp` moved from an isolated tier 5 into tier 3 (alongside the new `sheet_navigation`), so `auth`/`change_password`/`services`/`workers` (tier 4) can depend on it directly — no callback-seam workaround needed.
- Both new packages registered in the root `pubspec.yaml` `workspace:` list.
- `validate_deps --strict` and `scan_imports` both pass with only the same 4 + 11 pre-existing violations that were present before this work started (in `account_settings`, `organization_settings`, `bottom_nav_bar`, `media` for the dep-graph check; `organization_settings`, `registration`, `maps` for the import-layer check) — confirmed by running both validators before touching anything and diffing.
- `packages/permissions` (tier 2) deliberately still calls `showAppBottomSheet` directly rather than `SheetNavigator` — converting it would create an illegal upward dependency on `sheet_navigation` (tier 3). This is documented in the sheet_navigation README, not an oversight.
- `showAppActionSheet`/`showAppSelectSheet` call sites (worker/branch/service select sheets, permission dialogs, category picker's underlying `AppActionSheet`) were left on their existing design_system helpers; their scrim/footer/search chrome lives inside the helper itself, and re-hosting them under `SheetScaffold` would double that chrome without adding anything. Two call sites that already build on `AppActionSheet` directly (`EditCategoryBottomSheet`, `AssetSourceSheet`) were moved to `SheetNavigator.push` with `enableDrag: false, padChild: false` to avoid a doubled handle/padding while still gaining route-based nesting.

## 6. Test results

All numbers below are `flutter test --no-pub` runs, package by package, immediately after this work:

| Package | Tests | Result |
|---|---|---|
| `sheet_navigation` | 7 | ✅ all pass (incl. a 3-level nested push/pop back-stack test and a value-propagation-from-deepest-sheet test) |
| `otp` | 11 | ✅ all pass (7 bloc tests + 4 widget tests covering full success flow, cancel-via-barrier, invalid-code error display, resend-cooldown gating) |
| `auth` | 24 | ✅ all pass (includes new `AuthOtpVerifier` tests, and a pre-existing bug fix — see §9) |
| `invitation` | 6 | ✅ all pass (unchanged, pre-existing) |
| `organization_settings` | 11 | ✅ all pass (unchanged, pre-existing) |
| `branches` | 94 | ✅ all pass |
| `workers` | 39 | ✅ all pass |
| `maps` | 107 | ✅ all pass |
| `media` | 10 | ✅ all pass |
| `asset_picker` | 52 | ✅ all pass |
| **Total** | **361** | **✅ all pass** |

`dart analyze --fatal-infos` is clean (zero issues) in every file this work touched or created, across all ten packages above.

## 7. Performance verification — honest status

**Not profiled with real tooling.** This environment has no device/emulator or Flutter DevTools attached, so I cannot report actual frame-timing, GPU/raster numbers, or a rebuild-count trace for nested push/drag/dismiss. What I can state with confidence from the implementation itself:

- The morph animation and drag gesture are driven by a single `AnimatedBuilder` per sheet, listening to that sheet's own (already-existing) route `AnimationController` plus the `secondaryAnimation` Flutter already provides — no additional `Timer`/polling loop was introduced.
- `OtpBloc`'s resend countdown is a single `Timer.periodic` per active flow, cancelled in `close()`.
- No widget in the new code rebuilds more often than its narrowest `BlocBuilder`/`AnimatedBuilder` scope requires (verified by reading, not by a rebuild counter).

**Recommendation:** run the app on a real device with DevTools' "Track Widget Rebuilds" and the performance overlay while exercising a 3+ level nested-sheet push/dismiss before shipping, if this hasn't been done already.

## 8. Accessibility — honest status

**Not verified with TalkBack/VoiceOver** — no such device/simulator is available in this environment. What's structurally true: `AppOtpField`/`AppButton`/`AppTextField` etc. are unchanged design_system components with their existing semantics; this work did not remove or bypass any `Semantics` widget. Keyboard focus traversal was not specifically tested for the OTP sheet's field-to-button order.

**Recommendation:** a manual pass with TalkBack (Android) and VoiceOver (iOS) over the Edit-Email-with-OTP flow and a 2-level nested sheet before shipping.

## 9. Bonus fix (found during migration, unrelated to OTP/sheets)

`packages/features/auth/test/.../auth_bloc_test.dart`'s `AuthValidateEmailEvent` group had all four tests' mock stub booleans inverted relative to their assertions (e.g. "sign-up + email available → success" stubbed `emailAvailable: false`, which the bloc's own `!emailAvailable` logic turns into a failure branch). This was pre-existing and unrelated to my changes — confirmed by reverting only the test file to `HEAD` and observing it still fails to compile against my migrated bloc for reasons unconnected to this bug, then confirming the swapped-boolean pattern directly from the bloc's branching logic. Fixed by swapping the four stub values to match their test names.

## 10. Known limitations

- `sheet_navigation`'s `enableDrag` controls both "show the drag handle" and "allow drag-to-dismiss" as one flag — a handful of migrated call sites that previously hid only the handle (while keeping drag-dismiss) now lose drag-dismiss too (barrier-tap dismiss still works). Affected: `map_area_picker.dart`'s `showMapAreaPicker`.
- State restoration (`SheetRouteSettings.restorationId`) is accepted but not fully exercised — a multi-level nested sheet stack is not guaranteed to fully reconstruct after process death.
- No SMS autofill for the OTP field (paste/manual entry only).
- `AuthOtpVerifier`'s `OtpDelivery` is always a bare `const OtpDelivery()` — the auth backend's `requestEmailOtp` returns `void`, so there's no masked-destination/expiry metadata to surface yet.
- The Edit-Contact-Information → OTP integration in `organization_settings` mocks the email-change verification (`_OrganizationEmailOtpVerifier`) because there is no backend endpoint yet for confirming an organization email change. Swapping in a real `OtpVerifier` when that endpoint exists requires touching only that one class.
- `packages/organization_settings`, `packages/account_settings`, `packages/bottom_nav_bar`, and `packages/media` remain undeclared in `dep_rules.yaml`'s `layer_order` (pre-existing, confirmed present before this work started) — `validate_deps --strict` reports these regardless of this migration.

## 11. Future extension points

- Any new verification flow (forgot-password, change-password, delete-account, future MFA) needs only an `OtpVerifier<T>` implementation and a call to `OtpFlow.start` — no new UI.
- Any new picker/action sheet needs only `SheetNavigator.push(context, widget)` — nested pushes get the LinkedIn morph for free.
- `SheetRouteSettings.title`/`padChild` were added during this migration specifically so `showAppBottomSheet`'s `title`/`padChild` parameters had a direct equivalent — future parameters on the design_system helpers that need a `SheetNavigator` equivalent should follow the same pattern (thread through `SheetRouteSettings` → `ModalSheetRoute` → `SheetScaffold`).
