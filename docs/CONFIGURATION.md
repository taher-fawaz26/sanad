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
