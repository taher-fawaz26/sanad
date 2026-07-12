# Package Guide

## Package Inventory

### Core / Infrastructure

| Package | Description | Status |
|---------|-------------|--------|
| `core` | Failure, UseCase, DI base, validators, SVG assets | Active |
| `dependencies` | Centralized third-party re-export hub | Active |
| `config` | Pure-Dart env constants, feature flags, API URLs | Active |
| `flavors` | Flavor definitions (dev/qa/stage/prod) | Active |
| `network` | Dio client, interceptors, token management | Active |
| `storage` | Hive encrypted cache, secure token storage | Active |
| `app_logger` | App-level logger + BLoC observer | Active |
| `utilities` | Date/string/number formatting helpers | Active |
| `testing` | Shared test utilities, fakes, matchers | Active |

### Domain / Data

| Package | Description | Status |
|---------|-------------|--------|
| `domain` | Shared business domain entities and contracts | Active |
| `shared_models` | Domain entities shared across apps | Active |
| `api` | Remote API layer (endpoints, DTOs, repos) | Stub |

### Features

| Package | Description | Status |
|---------|-------------|--------|
| `auth` | Login, logout, register, session, auth BLoC | Active (reference) |
| `otp` | OTP verification flow | Active |
| `forgot_password` | Password reset flow | Active |
| `change_password` | Authenticated password update | Stub |
| `settings` | Settings feature | Stub (orphaned — not in workspace) |

### UI / Localization

| Package | Description | Status |
|---------|-------------|--------|
| `design_system` | Theme, colors, typography, tokens, components | Active |
| `shared_widgets` | Composite widgets on design system | Active |
| `localization` | EasyLocalization, TranslateBloc, validation keys | Active |
| `shared_blocs` | Backwards-compat re-export facade | Active |

### Platform

| Package | Description | Status |
|---------|-------------|--------|
| `analytics` | Firebase Analytics + Crashlytics | Stub |
| `notifications` | Firebase Messaging + local notifications | Stub |

## Creating a New Package

1. Create `packages/<name>/` with `pubspec.yaml` (`publish_to: none`)
2. Add to root `pubspec.yaml` workspace list
3. Add to `melos.yaml` packages list
4. Create `analysis_options.yaml` (include `very_good_analysis`)
5. Create `lib/<name>.dart` barrel file
6. Create `test/` folder
7. Run `melos bootstrap`
8. Add entry to this document

See `package_creation.skill.md` for detailed workflow.

## Dependency Rules

- Packages never import apps
- Direction: `apps → features → infra → core`
- No circular dependencies
- `dependencies` package is the third-party re-export hub
