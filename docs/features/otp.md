# OTP Verification (Shared)

## Purpose

The single one-time-code verification flow in the app. Every OTP surface —
authentication, account settings, organization settings, worker invitation,
account deletion — runs the same engine and the same screen; callers supply
only a verifier and what to do with the result.

## Location

- Engine, config, flow, UI: [`packages/otp/`](../../packages/otp/) (tier 3)
- Pin input: `packages/design_system/lib/src/components/app_otp_field.dart`
  (`AppOtpField`)
- Per-flow verifiers live with their backend, never in `otp`:
  - `packages/contact_verification/` — `ContactVerificationVerifier`
  - `packages/auth/` — `SignupOtpVerifier`, `LoginOtpVerifier`
  - `packages/account_settings/` — `DeletionOtpVerifier`
  - `apps/sanad_provider/.../invitation/` — `InvitationOtpVerifier`

## User Flow

The screen opens → the engine reads the server's cooldown → it sends a code
**only if no session is already live** → the user types → verification runs on
the last digit (`autoSubmit`) or on an explicit Verify tap → a countdown gates
Resend.

## Architecture

`packages/otp` owns **no network code at all** and sits below every feature
package in `dep_rules.yaml` (tier 3 vs. `contact_verification`/`auth` at 4 and
`account_settings` at 5). Every backend fact therefore reaches it through one
injected port:

```dart
abstract interface class OtpVerifier<T> {
  TaskEither<Failure, OtpDelivery> requestCode();   // open a session
  TaskEither<Failure, OtpDelivery> resendCode();    // resend on it
  TaskEither<Failure, OtpCooldown>? cooldown();     // null = no such endpoint
  TaskEither<Failure, T> verifyCode(String code);
}
```

`OtpVerifierBase<T>` supplies defaults so a flow with no resend/cooldown
endpoints implements two methods.

- `OtpFlow.start<T>(context, config)` — pushes a sheet or page, returns an
  `OtpResult<T>`.
- `OtpHost<T>` — the same bloc + UI, reporting through a callback instead of
  popping. Used where the screen is embedded in a host's own chrome (the auth
  shell).
- `OtpView<T>` — the canonical screen. Sheet and page differ **only** in the
  container around it.

## Main State Management

`packages/otp/lib/src/presentation/bloc/otp/otp_bloc.dart`.

Phases: `OtpIdle`, `OtpSending`, `OtpAwaitingInput`, `OtpVerifying`,
`OtpVerifiedPhase`, `OtpInvalidCode`, `OtpExpiredPhase`, `OtpDispatchFailed`,
`OtpConflict`. State carries `code`, `destination`, `cooldown`,
`cooldownEndsAt`, `isResending`, `verifiedData`.

There is deliberately **no cooldown phase** — a live cooldown is data, not a
mode. The previously issued code is still valid, so the field stays open while
the countdown runs.

## API Dependencies

Every OTP family on the backend exposes the same cooldown resource, which is
what makes one engine possible:

```
GET /api/v1/contact-verification/resend-info?purpose=<enum>
GET /api/v1/auth/resend-info?email=<email>
GET /api/v1/account/deletion/resend-info
GET /api/v1/workers/invitations/resend-info/{token}

→ { canResend, remainingSeconds, attemptsLeft }
```

Send/verify pairs: `contact-verification/{request,resend,verify}`,
`auth/{signup,login}` + `/verify` + `auth/resend-otp`,
`account/deletion{,/verify,/resend-otp}`,
`workers/invitations/{request-otp,resend-otp}` + `/accept`.

The authoritative spec is **live** at `https://dev-api.trysanad.us/api/docs-json`
(no auth needed with a `Referer` header; `tools/sanad-mcp` loads it). No
OpenAPI file is committed — read the live spec rather than inferring from Dart.

## Business Rules

- **Read before write.** Sessions are server-side, keyed (account, purpose), and
  outlive the sheet. The engine probes `cooldown()` before dispatching, so
  reopening a flow inside a live cooldown shows a countdown instead of
  provoking a 429.
- **A 429 is never an error.** It means a valid code is already out there; it
  seeds the countdown.
- **Two error slots, never merged.** Code errors (wrong, expired) render under
  the field; dispatch errors (address taken, forbidden purpose, outage) render
  in a banner above the title with a Retry.
- `attemptsLeft` counts **resends**, not wrong-code tries. No endpoint in the
  contract exposes a verification-attempt counter, so the UI shows none.
- Cooldown ticks against a wall-clock anchor, so backgrounding cannot
  desynchronise it. `AppDurations.otpResendCooldown` (60s) is a **fallback
  only**, used when a flow has no `resend-info` endpoint.
- The visible digit cells are a pure projection of one hidden `TextField`'s
  value and selection (deliberately not `pinput`).
- **Every cell is a fixed position.** While focused and not past the end, a
  position is always *selected*, so each keystroke replaces rather than
  inserts, and the caret auto-advances one cell. See
  `_armSelection` in `app_otp_field.dart`.
- OTP digits stay LTR in Arabic; so does the `mm:ss` countdown.
- Tapping a cell always re-opens the keyboard, including after the platform
  down-chevron dismissed it (SAN-569).

## Important Constraints

- The blinking caret animation repeats indefinitely — tests must use bounded
  `pump()`, never `pumpAndSettle()`, while the field has focus.
- `autoSubmit: false` wherever a wrong code is costly (auth, deletion):
  re-editing a digit of a full code would otherwise re-fire verification
  (SAN-539).

## Known Issues

- No verification-attempt counter is displayed. The UI slot exists; it stays
  empty until the backend adds `verifyAttemptsLeft` to `resend-info`.
- No SMS autofill (paste / manual entry / one-time-code autofill only).

## Relevant Source Files

- `packages/otp/lib/src/presentation/bloc/otp/otp_bloc.dart`
- `packages/otp/lib/src/presentation/view/otp_view.dart`
- `packages/otp/lib/src/domain/contracts/otp_verifier.dart`
- `packages/design_system/lib/src/components/app_otp_field.dart`

## Related Documentation

[`../../.claude/rules/ui.md`](../../.claude/rules/ui.md) ·
[`../../.claude/rules/state-management.md`](../../.claude/rules/state-management.md) ·
[`../../.claude/rules/networking.md`](../../.claude/rules/networking.md)
