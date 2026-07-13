# Configuration

## Environment Selection

```bash
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
# Development (default)
flutter run

# QA
flutter run --dart-define=ENV=qa

# Production build
melos build:provider:android -- --dart-define=ENV=prod
```

See `FLAVORS.md` for detailed flavor documentation.
