# Flavors

## Overview

Sanad uses four build environments (flavors) selected via `--dart-define=ENV=<flavor>`.

## Flavor Matrix

| Flavor | Base URL | Purpose |
|--------|----------|---------|
| **dev** | `https://dev-api.trysanad.us/api/v1/` | Local development (default) |
| **qa** | `https://qa-api.trysanad.us/api/v1/` | QA testing |
| **stage** | `https://stage-api.trysanad.us/api/v1/` | Pre-production staging |
| **prod** | `https://api.trysanad.us/api/v1/` | Production release |

## Development (dev)

- **Default** — used when no `ENV` is specified
- Points to development API server
- Verbose logging enabled
- Used for daily development and debugging

```bash
flutter run                                    # defaults to dev
flutter run --dart-define=ENV=dev              # explicit
```

## QA (qa)

- QA team's testing environment
- Mirrors production configuration with test data
- Used for feature validation before staging

```bash
flutter run --dart-define=ENV=qa
```

## Stage (stage)

- Pre-production environment
- Production-like configuration
- Final validation before release

```bash
flutter run --dart-define=ENV=stage
```

## Production (prod)

- Live production API
- Logging minimized
- Used for store releases only

```bash
melos build:provider:android -- --dart-define=ENV=prod
melos build:client:android -- --dart-define=ENV=prod
melos build:provider:ios -- --dart-define=ENV=prod
melos build:client:ios -- --dart-define=ENV=prod
```

## Package Structure

```
packages/config/     → AppConfig, NetworkConfig, FeatureFlags (pure Dart)
packages/flavors/    → Maps ENV to concrete URLs, Firebase IDs, flag overrides
apps/*/config/       → App-level adapter reading ENV dart-define
```

## Feature Flag Overrides

Each flavor can override feature flags in `packages/flavors`:

| Flag | dev | qa | stage | prod |
|------|-----|-----|-------|------|
| Analytics | off | on | on | on |
| Push notifications | off | on | on | on |
| Debug logging | on | on | off | off |

## Build Process

1. Select flavor via `--dart-define=ENV=<flavor>`
2. `packages/flavors` resolves concrete config values
3. `apps/*/config/app_config.dart` adapts for the app
4. `app_di.dart` registers `NetworkConfig` with resolved base URL
5. Dio instances created with correct base URL and timeouts

## Environment Mapping

```
--dart-define=ENV=dev
  → packages/flavors/dev.dart
  → packages/config/AppConfig
  → apps/*/config/app_config.dart
  → app_di.dart (NetworkConfig registration)
  → Dio(baseUrl: resolved URL)
```
