# Configuration

## Environment Selection

Run from an app directory — the repository root is a Melos workspace, not a Flutter app:

```bash
cd apps/sanad_provider   # or apps/sanad_client
flutter run --dart-define=ENV=dev     # Default
flutter run --dart-define=ENV=qa
flutter run --dart-define=ENV=stage
flutter run --dart-define=ENV=prod
```

## Package Ownership

| Package | Role | Flutter Dependency |
|---------|------|-------------------|
| `packages/config` | Pure-Dart constants | No |
| `packages/flavors` | ENV → concrete values | No |
| `apps/*/lib/src/config/` | App-level adapter | Yes |

## Base URLs

| ENV | URL |
|-----|-----|
| dev | `https://dev-api.trysanad.us/api/v1/` |
| qa | `https://qa-api.trysanad.us/api/v1/` |
| stage | `https://stage-api.trysanad.us/api/v1/` |
| prod | `https://api.trysanad.us/api/v1/` |

## Network Configuration

```dart
// packages/config
class NetworkConfig {
  final String baseUrl;
  final Duration connectTimeout;  // 15s default
  final Duration receiveTimeout;  // 15s default
  final Duration sendTimeout;     // 15s default
  final String refreshPath;       // 'auth/refresh'
}
```

## Maps / Places API key (`MAPS_API_KEY`)

Google Places autocomplete (the location & coverage-area search sheets) needs a
Google API key, supplied as the `MAPS_API_KEY` dart-define. It is read in
`apps/sanad_provider/lib/src/di/app_di.dart` via `String.fromEnvironment`. When
absent/empty the maps package falls back to keyless mode (no autocomplete) — see
`MapsConfig.placesEnabled`.

Keys are provided per platform through git-ignored dart-define files:

```
apps/sanad_provider/dart_defines/
  android.example.json   # committed template ({ "MAPS_API_KEY": "" })
  ios.example.json       # committed template
  android.json           # real key — git-ignored, local only
  ios.json               # real key — git-ignored, local only
```

Local setup — copy each template and fill in the platform key:

```bash
cd apps/sanad_provider
cp dart_defines/android.example.json dart_defines/android.json
cp dart_defines/ios.example.json    dart_defines/ios.json
# then paste the real key into each
```

Launch configs (`.vscode/launch.json`) and the `build:provider:*` melos scripts
already pass `--dart-define-from-file=dart_defines/<platform>.json`. **CI injects
the real values** by writing these files (or overriding the define) at build
time. Real keys are never committed — only the `*.example.json` templates are.

The Firebase Distribution workflow (`.github/workflows/firebase-distribution.yml`)
injects the **`MAPS_API_KEY_ANDROID`** secret into the `sanad_provider` Android
build in **two** places before building:

1. `dart_defines/android.json` — the dart-define read by Dart for the Maps REST
   calls (serving-area discovery). Without it the APK silently returns zero
   areas (`NoopNearbyAreasRepository`).
2. `android/local.properties` — the source of the `MAPS_API_KEY` manifest
   placeholder (`android/app/build.gradle.kts`), which the **native** Maps SDK
   reads to render map tiles. Without it the map picker shows a blank
   background (SAN-598).

The map also requires a stable release signing certificate — see
[Android release signing (CI)](#android-release-signing-ci--maps-sha-restriction)
below. `sanad_client` doesn't use Maps and needs neither.

## Android release signing (CI) & Maps SHA restriction

The Google Maps **Android** API key is restricted to *package name + release
SHA-1* (see `android/local.properties.example`). For the restriction to hold,
every Firebase App Distribution build must be signed with the **same** release
certificate — otherwise the SHA-1 changes per build and the map renders blank
tiles (SAN-598). CI therefore signs `sanad_provider` with a **persistent
release keystore**, not the runner's ephemeral debug keystore.

### How it wires together

- `android/app/build.gradle.kts` uses the `release` signingConfig **only when
  `android/key.properties` exists**; otherwise it falls back to debug signing.
  A dev machine has no `key.properties`, so local builds are unchanged.
- `.github/workflows/firebase-distribution.yml` (provider only) decodes the
  keystore from a secret, writes `key.properties`, builds, then runs
  `apksigner verify --print-certs` to confirm the APK is signed with the
  release cert (fails if it's still the debug cert) and — when
  `ANDROID_RELEASE_CERT_SHA256` is set — asserts the fingerprint hasn't drifted.
- Nothing signing-related is committed: `android/.gitignore` already ignores
  `key.properties`, `**/*.jks`, `**/*.keystore`, and `/local.properties`.

### Required GitHub secrets / variables (`development` environment)

The four signing **secrets** already exist on the `development` environment
under the `PROVIDER_ANDROID_*` names; the workflow consumes them directly.

| Name | Kind | Value |
|------|------|-------|
| `PROVIDER_ANDROID_KEYSTORE_BASE64`   | secret | `base64 -w0` of the `.jks` file |
| `PROVIDER_ANDROID_KEYSTORE_PASSWORD` | secret | keystore/store password |
| `PROVIDER_ANDROID_KEY_PASSWORD`      | secret | key password |
| `PROVIDER_ANDROID_KEY_ALIAS`         | secret | key alias (e.g. `sand-provider`) |
| `ANDROID_RELEASE_CERT_SHA256`        | variable (optional) | expected cert SHA-256 to enforce reproducibility — **the only piece not yet configured** |

### Keystore provenance and reading its fingerprints

The release keystore already exists and is stored in the `PROVIDER_ANDROID_*`
secrets above — **do not generate a new one** (that would change the certificate
and invalidate the Maps SHA-1 restriction). The commands below are the reference
for how it was created and how to read its (public) fingerprints from a local
copy of the `.jks`:

```bash
# Reference only — how the keystore was generated (PKCS12, ~27-year validity):
keytool -genkeypair -v -keystore sand-provider-release.jks -storetype PKCS12 \
  -keyalg RSA -keysize 2048 -validity 10000 -alias sand-provider

# SHA-1 (register on the Maps key) and SHA-256 (for the CERT variable / App Links)
keytool -list -v -keystore sand-provider-release.jks -alias sand-provider \
  | grep -E "SHA1:|SHA256:"

# Base64 for the PROVIDER_ANDROID_KEYSTORE_BASE64 secret (no line wrapping)
base64 -w0 sand-provider-release.jks       # macOS: base64 -i sand-provider-release.jks
```

### Google Cloud / Firebase configuration that must match

- **Maps Android API key** (Google Cloud → APIs & Services → Credentials →
  *Application restrictions: Android apps*): one entry with
  package `com.sanad.provider` **+** the release **SHA-1** above. Keep the
  existing debug SHA-1 entry so local debug builds keep working — **do not
  remove or loosen** existing restrictions.
- Store the printed release SHA-256 in the `ANDROID_RELEASE_CERT_SHA256`
  variable so CI enforces that every build uses this exact certificate.
- (If Android App Links `autoVerify` is later enabled for these hosts, the same
  release **SHA-256** must also go into each host's `assetlinks.json`.)

`sanad_client` (`com.sanad.client`) does not use Maps and keeps the debug-signing
fallback — its distribution behavior is intentionally unchanged.

## Feature Flags

Defined in `FeatureFlags` class in `packages/config`:

```dart
class FeatureFlags {
  final bool enableAnalytics;
  final bool enablePushNotifications;
  // Per-environment overrides in packages/flavors
}
```

## App Configuration

Each app adapts config via `apps/*/lib/src/config/app_config.dart`:

```dart
class AppConfig {
  static NetworkConfig get network => /* reads ENV dart-define */;
}
```

Registered in `app_di.dart` during bootstrap.

## Rules

- Never hardcode base URLs or API keys in source
- `packages/config` must remain pure Dart (no `flutter` dependency)
- No user-facing config mutation at runtime — all config is build-time
- Secrets via `--dart-define` only — never in source code

## Build Commands with Config

```bash
cd apps/sanad_provider   # or apps/sanad_client

# Development (default)
flutter run

# QA
flutter run --dart-define=ENV=qa

# Production build
melos build:provider:android -- --dart-define=ENV=prod
```

See `FLAVORS.md` for detailed flavor documentation.
