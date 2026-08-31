# App Lock — local biometric / device authentication

A convenience gate over an **already-authenticated session**. It is not, and
must never become, a substitute for backend authentication.

```
Backend Auth / Session   →   Local Authentication Gate   →   Authenticated App
```

Shipped in both `sanad_provider` and `sanad_client`.

---

## What is and is not stored

Stored — the user's *preference* only, in Keychain/Keystore via
`SecureLocalStorage`:

| Key | Meaning |
|---|---|
| `app_lock_enabled_v1` | The lock is switched on |
| `app_lock_offered_v1` | The post-login offer has been answered (either way) |

**Never stored:** biometric data, fingerprint templates, Face ID data, the
device PIN/passcode. Those belong to the OS and never reach the app.

The preference deliberately does **not** live in the Hive default box: that box
is unencrypted (`HiveEncryptionKeyManager._secureBoxes` covers `session_box`
only), and a security toggle that can be flipped by editing a plaintext file on
a rooted device is not a security toggle.

---

## Where the code lives

| Concern | Location |
|---|---|
| `local_auth` plugin boundary | `packages/device/lib/src/infrastructure/providers/biometric_provider.dart` |
| Domain contract / results | `packages/device` — `BiometricService`, `BiometricAuthResult`, `BiometricAuthStatus`, `BiometricType` |
| Preference + capability | `packages/account_settings` — `AppLockRepository` / `AppLockRepositoryImpl` |
| State machine | `packages/account_settings/lib/src/presentation/lock/app_lock_controller.dart` |
| Gate widget / lock screen | `.../lock/app_lock_gate.dart`, `.../lock/app_lock_screen.dart` |
| Post-login offer | `.../lock/app_lock_offer.dart` |
| Enable/disable orchestration | `.../bloc/security/security_bloc.dart` |
| Settings UI | `.../widgets/sections/security_section.dart` |
| Per-app lifecycle wiring | `apps/<app>/lib/src/lock/app_lock_binding.dart` |

**No feature imports `local_auth`.** `packages/device` is the only package that
depends on it, per that package's stated charter.

---

## State machine

`AppLockController` (one lazy-singleton instance, shared by the gate and the
settings toggle).

```
enum AppLockState { unknown, unlocked, locked, authenticating, unavailable }
```

| From | Trigger | To |
|---|---|---|
| `unknown` | flag off, preference off, or no session | `unlocked` |
| `unknown` | preference on + session + capability available | `locked` → prompt |
| `unknown` | preference on, device can authenticate nobody | `unavailable` (fails **open**) |
| `locked` | `authenticate()` | `authenticating` |
| `authenticating` | success | `unlocked` |
| `authenticating` | anything else | `locked` (+ `lastFailure`, no auto-retry) |
| `unlocked` | app paused | `locked` |
| any | session cleared | `unlocked` |
| any | preference switched off | `unlocked` |

Attempt outcomes (`failed`, `lockedOut`, …) are **not states**. After an
unsuccessful attempt the gate is simply still `locked`; the status rides along
in `lastFailure` purely to choose the lock screen's copy.

State is **never persisted** — it is derived at every cold start, so process
death always re-locks.

### `unknown` is not open

Nothing protected renders while the preference and capability are unknown.
Guessing either way would be wrong: guessing open leaks content, guessing
locked prompts users who never enabled the feature.

---

## Lifecycle policy

- **Locks on `paused`, not `resumed`** — the lock screen is then already in
  place before the OS takes its app-switcher snapshot, and repeated `resumed`
  events cannot each raise a prompt.
- **`inactive` and `hidden` are ignored.** The biometric sheet itself drives the
  app inactive on iOS; treating that as "left the foreground" would re-lock the
  app that is currently showing the unlock prompt.
- **No grace window, no timer.** Every foreground return re-locks. This is a
  product decision, not an oversight — it is why there is no clock, no
  `DateTime.now()`, and no background-duration bookkeeping anywhere in the
  feature.
- **No auto-retry after a failure.** The user must press Unlock. This is what
  prevents a prompt loop.
- **One `authenticate()` at a time.** `AppLockController._inFlight` returns the
  existing future to a second caller rather than raising a second OS prompt.

---

## Enable / disable

Both directions require a **successful local authentication before anything is
persisted** (`SecurityBloc`):

- **Enable** proves the user can actually pass the gate they are putting in
  front of themselves.
- **Disable** proves the person holding an already-unlocked phone is the owner,
  and not someone quietly removing the lock (fails closed, per
  `.claude/rules/security.md`).

`AppSwitch.loading` holds the previous value while the OS prompt is up, so the
UI never shows a state the user has not earned.

### The one relaxation

If the device can no longer authenticate anyone (screen lock removed after the
fact), disabling is allowed without a prompt — and the gate treats the same
condition as `unavailable`. The two agree, so no lock-out is reachable.

### Fail-open vs fail-closed

- **Fail closed** on every *authentication* outcome — any non-success keeps the
  gate shut.
- **Fail open** on *capability loss* — the session is still protected by tokens
  and routing, and failing closed here would permanently brick the app for a
  user no credential can let in.

---

## Session interaction

The gate protects **access to** an existing session; it does not protect
credential storage. Tokens already live in `flutter_secure_storage`
(`TokenStorageImpl`) and the session snapshot in an AES-encrypted Hive box, so
the OS keychain/keystore already protects the credential at rest.

Invariants:

1. "Enabled" is never treated as evidence of backend authentication.
2. No token or session validation is bypassed — the gate sits *above* the
   router, and every redirect, 401 refresh, and `AuthStatusNotifier` transition
   runs unchanged underneath it.
3. Protected content is **replaced**, not covered: while locked, the routed
   subtree is not built at all.
4. The lock screen carries a **Log out** action, so a user who cannot pass the
   gate (broken sensor, forgotten passcode) is never bricked.
5. A session that ends mid-prompt does not unlock into a dead session.
6. The preference is **retained across logout** — it is a device-level
   convenience, and clearing it on every session boundary would silently
   disable security after a transient refresh failure.
7. Nothing biometric is logged.

### Why not a router redirect, and why not `AuthBloc`

A redirect-based lock would need lock state in `AuthStatusNotifier` — which is
`refreshListenable` for *both* routers and the RBAC table — and would fight
`resolveProviderRedirect`'s precedence chain and break deep links. `AuthBloc`
was left untouched because the gate needs no auth events, only
`SessionManager.current()`.

Deep links survive: the `GoRouter` instance is owned by the app and outlives
the gate's `child`, so the pending location is still there when the routed app
is remounted.

---

## Kill switch

`FeatureFlags.enableBiometricLogin`, supplied per app by
`AppConfig.featureFlags` and registered in `configureDependencies()`. With it
off the gate stays open and no prompt is ever raised. It is on in every
environment — the switch exists so the feature can be disabled in a hotfix
build, not to stage a rollout.

---

## Platform setup

### Android (both apps)

- `MainActivity` extends **`FlutterFragmentActivity`** — `local_auth_android`
  requires a `FragmentActivity` to host `BiometricPrompt`; with `FlutterActivity`
  every call fails at runtime with `no_fragment_activity`.
- `LaunchTheme` / `NormalTheme` inherit from **`Theme.AppCompat.*`**. minSdk is
  24, and on API 24–27 `androidx.biometric` falls back to an AppCompat
  `AlertDialog`, which only resolves under a `Theme.AppCompat` descendant.
- `androidx.appcompat:appcompat` is declared explicitly in `app/build.gradle.kts`
  so the theme's requirement does not rest on a transitive dependency.
- `USE_BIOMETRIC` is declared in the manifest (also contributed by the plugin;
  declared locally so the permission surface is auditable in one file).

### iOS (both apps)

- `NSFaceIDUsageDescription` in `Info.plist` — Face ID crashes the app without
  it. Deployment targets (15.5 provider, 13.0 client) both exceed the plugin's
  iOS 12 floor.
- The plist string is OS-rendered and is **not** localizable through
  `easy_localization`; Arabic copy would need `InfoPlist.strings`.

---

## Plugin limitation worth knowing

`local_auth` 2.3.0 defines **no cancellation error code**. A dismissed prompt
and a failed match both arrive as `authenticate() == false`, so
`BiometricAuthStatus.cancelled` is unreachable and no UI may claim to
distinguish them. A regression test in
`packages/device/test/src/infrastructure/biometric_provider_test.dart` pins
this.

`isDeviceSupported()` is `isDeviceSecure() || canAuthenticateWithBiometrics()`.
Because the gate runs with `biometricOnly: false`, a device with a passcode and
**zero enrolled biometrics** authenticates fine — which is why capability is
binary (`available` / `unsupported`) and "not enrolled" is not a blocking state.
Enrolled types are used only to word the settings copy.

---

## Tests

| Area | File |
|---|---|
| Plugin error mapping, cancellation guard | `packages/device/test/src/infrastructure/biometric_provider_test.dart` |
| Persistence, restart, memoised capability | `packages/account_settings/test/src/data/repositories/app_lock_repository_impl_test.dart` |
| State machine, lifecycle, concurrency | `.../test/src/presentation/lock/app_lock_controller_test.dart` |
| Gate — protected content never leaks | `.../test/src/presentation/lock/app_lock_gate_test.dart` |
| Enable/disable security rule | `.../test/src/presentation/bloc/security/security_bloc_test.dart` |
| Settings row | `.../test/src/presentation/widgets/sections/security_section_test.dart` |

### Not covered by unit tests — verify on device

Android fingerprint + PIN fallback; iOS Face ID + passcode fallback; lockout
after repeated failures; a device with no screen lock; Arabic RTL layout of the
Security section and lock screen; airplane-mode cold start (the gate must not
require network).
