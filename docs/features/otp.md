# OTP Verification (Shared)

## Purpose

Reusable one-time-code verification used in the login and registration flows:
renders the code field, destination + change action, inline error, and a
resend timer.

## Location

- Flow/view/bloc: [`packages/otp/`](../../packages/otp/)
- The pin input widget: `packages/design_system/lib/src/components/app_otp_field.dart`
  (`AppOtpField`).

## User Flow

User lands on "Enter Verification Code" → types the code into the pin field →
either auto-submits on completion (`autoSubmit`) or taps Verify → on failure an
inline error shows; a countdown gates "Resend", after which the user can request
a new code.

## Architecture

`OtpVerificationView<T>` (a `StatefulWidget`) renders from `OtpBloc<T>` state and
is parameterized by an `OtpFlowConfig<T>` (title/subtitle builders, length,
`autoSubmit`, `onChangeDestination`, submit handling).

## Main Screens

- `packages/otp/lib/src/presentation/view/otp_verification_view.dart`

## Main State Management

- `packages/otp/lib/src/presentation/bloc/otp/otp_bloc.dart` — phases include
  `OtpIdle`, `OtpSending`, `OtpVerifying`, `OtpInvalidCode`, `OtpExpiredPhase`,
  `OtpFailurePhase`; events `OtpCodeChanged`, `OtpSubmitted`, `OtpResendRequested`,
  `OtpDestinationChanged`. State carries `code`, `destination`, `canResend`,
  `secondsRemaining`.

## Domain Models

Config/entities in `packages/otp/lib/src/` (`OtpFlowConfig`, phase types).

## API Dependencies

Send/verify handled through the OTP flow config's callbacks (backend send/verify
endpoints wired per consumer). `NEEDS_CONFIRMATION` for exact endpoint paths.

## External Integrations

Autofill via `AutofillHints.oneTimeCode` on the hidden input.

## Business Rules

- The visible digit cells are a pure projection of a single hidden `TextField`'s
  value/selection — one source of truth (deliberately not `pinput`).
- OTP digits stay LTR even in Arabic layouts.
- Tapping a filled cell selects that digit for in-place replacement.
- Tapping a cell always re-opens the keyboard, including after the user dismissed
  it via the platform down-chevron (SAN-569 — `TextInput.show` on an already-
  focused field).

## Important Constraints

- The blinking caret animation repeats indefinitely — tests must use bounded
  `pump()`, never `pumpAndSettle()`, while the field has focus.

## Known Edge Cases

- Programmatic value changes (clear/paste/autofill) are reported through
  `onChanged` because the widget listens on the controller, not only
  `TextField.onChanged`.

## Known Issues

- None open.

## Relevant Source Files

- `packages/design_system/lib/src/components/app_otp_field.dart`
- `packages/otp/lib/src/presentation/view/otp_verification_view.dart`
- `packages/otp/lib/src/presentation/bloc/otp/otp_bloc.dart`

## Related Documentation

[`../../.claude/rules/ui.md`](../../.claude/rules/ui.md) ·
[`../../.claude/rules/state-management.md`](../../.claude/rules/state-management.md)
