# otp

A reusable OTP verification flow. Any feature invokes it with one call —
`OtpFlow.start(context, config)` — and gets back a typed result. This package
owns **zero network endpoints**: the caller injects an `OtpVerifier` that
knows how to send and verify a code against whatever backend the caller
already has.

There is exactly one OTP implementation in the app. `auth` (email login/
signup), `invitation`, and `organization_settings` (email change) all use it.

## Why this exists

Before this package, OTP existed three separate times: a hand-rolled
`Timer.periodic` countdown in `auth`'s `EmailOtpPage`, a fully mocked screen
in `invitation`, and a set of orphaned, never-wired localization strings for a
phone/email flow that was never built (including stale copy claiming a
5-digit code against a backend that actually issues 6). None of them shared
state machine, timer, or UI code.

## Architecture

```
lib/
  otp.dart                              barrel
  src/
    domain/
      contracts/otp_verifier.dart       OtpVerifier<T> — the injected seam
      entities/otp_result.dart          sealed OtpResult<T>
      entities/otp_delivery.dart        OtpDelivery (result of requestCode())
      enums/otp_channel.dart            email | phone
      enums/otp_purpose.dart            drives default copy only
    data/
      verifiers/callback_otp_verifier.dart   OtpVerifier built from two closures
    presentation/
      config/otp_flow_config.dart       OtpFlowConfig<T> — the one knob-set
      bloc/otp/{otp_bloc,otp_event,otp_state}.dart
      flow/otp_flow.dart                OtpFlow.start<T>() — the public entry
      pages/otp_verification_page.dart  hosts the bloc, presentation-neutral
      view/otp_verification_view.dart   entry field, timer, resend, errors
      view/otp_success_view.dart        check-badge success screen
    di/otp_di.dart                      no-op (nothing to register)
    module/otp_module.dart              FeatureModule (no routes)
```

`domain/contracts/otp_verifier.dart` has no Flutter import — it's a pure
contract. Everything that touches `BuildContext` (the config's
`onChangeDestination` callback, the widgets) lives under `presentation/`.

## Public API

```dart
abstract final class OtpFlow {
  static Future<OtpResult<T>> start<T>(BuildContext context, OtpFlowConfig<T> config);
}

class OtpFlowConfig<T> {
  const OtpFlowConfig({
    required OtpChannel channel,
    required String destination,           // display value, e.g. "+20 123 456 7890"
    required OtpVerifier<T> verifier,
    OtpPurpose purpose = OtpPurpose.custom, // drives default title/subtitle only
    int length = kDefaultOtpLength,          // 6
    Duration? resendCooldown,                // defaults to AppDurations.otpResendCooldown
    bool autoSendOnStart = true,
    bool autoSubmit = true,
    bool showSuccessScreen = true,
    Duration successAutoCloseDelay = const Duration(seconds: 2),
    Future<String?> Function(BuildContext)? onChangeDestination,
    bool presentAsSheet = true,              // false pushes a plain page instead
    String Function(BuildContext, OtpFlowConfig<T>)? titleBuilder,
    String Function(BuildContext, OtpFlowConfig<T>)? subtitleBuilder,
  });
  const OtpFlowConfig.email({required destination, required verifier, ...});  // purpose defaults to verifyEmail
  const OtpFlowConfig.phone({required destination, required verifier, ...});  // purpose defaults to verifyPhone
}

abstract interface class OtpVerifier<T> {
  TaskEither<Failure, OtpDelivery> requestCode();       // send / resend
  TaskEither<Failure, T> verifyCode(String code);       // verify
}

class CallbackOtpVerifier<T> implements OtpVerifier<T> {
  const CallbackOtpVerifier({required onRequestCode, required onVerifyCode});
}

sealed class OtpResult<T> {}
class OtpVerified<T> extends OtpResult<T> { final T data; }
class OtpCancelled<T> extends OtpResult<T> {}
class OtpExpired<T> extends OtpResult<T> {}
class OtpFailed<T> extends OtpResult<T> { final Failure failure; }
extension OtpResultX<T> on OtpResult<T> { bool get isVerified; }
```

## Basic usage

```dart
final result = await OtpFlow.start<AuthResponseEntity>(
  context,
  OtpFlowConfig.email(
    destination: email,
    verifier: AuthOtpVerifier(email: email, requestEmailOtp: ..., verifyEmailOtp: ...),
  ),
);

switch (result) {
  case OtpVerified(:final data):
    // data is whatever your OtpVerifier.verifyCode resolved to
  case OtpCancelled():
  case OtpExpired():
  case OtpFailed(:final failure):
    // handle
}
```

For a call site with no real backend yet (a demo flow, or a feature waiting
on an endpoint), use `CallbackOtpVerifier` instead of writing a class:

```dart
verifier: CallbackOtpVerifier<void>(
  onRequestCode: () => TaskEither.right(const OtpDelivery()),
  onVerifyCode: (code) => TaskEither(() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return right(null);
  }),
),
```

## Writing an `OtpVerifier`

An `OtpVerifier<T>` is the only thing a new call site needs to write. It has
exactly two responsibilities:

1. `requestCode()` — call your backend's send-OTP endpoint, map the (likely
   `void`) response to an `OtpDelivery`.
2. `verifyCode(code)` — call your backend's verify endpoint, return whatever
   the caller of `OtpFlow.start` should receive on success.

Any side effect that must happen the moment verification succeeds (starting a
session, updating an in-memory status notifier, persisting the new value)
belongs **inside** `verifyCode`, not in the caller of `OtpFlow.start` — see
`AuthOtpVerifier` in `packages/features/auth/lib/src/domain/verifiers/` for the
reference implementation: it wraps `RequestEmailOtpUseCase`/
`VerifyEmailOtpUseCase` and, on a successful verify, starts the session and
updates `AuthStatusNotifier` before resolving.

## OTP lifecycle (`OtpBloc`)

```
OtpStarted
  → (autoSendOnStart) verifier.requestCode() → OtpSending → OtpAwaitingInput
  → starts resend countdown (bloc-owned Timer, ticks via OtpTimerTicked)

OtpCodeChanged(code)      → updates state.code, clears a stale error
OtpSubmitted([code])      → OtpVerifying → verifier.verifyCode(code)
  success → OtpVerifiedPhase(data)
  failure → OtpExpiredPhase (if Failure.code is in kOtpExpiredFailureCodes)
          → OtpInvalidCode(failure) otherwise

OtpResendRequested        → re-runs requestCode() (ignored while countdown is still running)
OtpDestinationChanged(d)  → resets code, re-requests against the new destination
OtpDismissed               → cancels the timer
```

`OtpVerificationPage` listens for `OtpVerifiedPhase`, shows `OtpSuccessView`
for `successAutoCloseDelay`, then pops the route with
`OtpVerified<T>(state.verifiedData)`. Any other dismissal (back, barrier tap,
drag) pops with `null`, which `OtpFlow.start` maps to `OtpCancelled<T>()`.

## Migration guide (from a hand-rolled OTP screen)

1. Delete the screen's local `Timer`/`Cubit`/countdown state — `OtpBloc` owns
   this now.
2. Write (or reuse) an `OtpVerifier<T>` wrapping your existing use
   cases/repository calls. If there's a post-verify side effect (session
   start, cache update), do it inside `verifyCode`.
3. Replace the screen's route/push with `OtpFlow.start<T>(context, config)`
   and switch on the returned `OtpResult<T>`.
4. Delete the old screen's localization keys once nothing references them
   (`otp.*` in this package's locale entries already covers title/subtitle/
   verify/resend/error copy — you likely don't need new keys at all).

## Dos and don'ts

- **Do** put post-verify side effects inside your `OtpVerifier`, not in the
  widget that called `OtpFlow.start`.
- **Do** use `OtpFlowConfig.email`/`.phone` factories over the base
  constructor when the channel is known — they set a sensible default
  `purpose`.
- **Don't** reach into `OtpBloc`/`OtpState`/`OtpEvent` from outside this
  package — they're exported for the package's own pages/tests, not as a
  public integration surface. `OtpFlow.start` is the integration surface.
- **Don't** build a second OTP screen. If the UI needs to look different for
  a given flow, use `titleBuilder`/`subtitleBuilder`/`purpose`, not a fork.

## Known limitations

- SMS autofill (reading an incoming SMS code automatically on Android/iOS) is
  not implemented — `AppOtpField` supports paste/manual entry only today.
- `OtpFlowConfig.onChangeDestination` expects the caller to handle navigating
  back to an email/phone entry step; this package does not provide a generic
  "edit destination inline" UI.
