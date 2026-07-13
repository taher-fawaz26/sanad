# Package Guide

## Package Inventory

### Core / Infrastructure

| Package | Description | Status |
|---------|-------------|--------|
| `core` | Failure, UseCase, DI base, validators, extensions | Active |
| `app_assets` | Shared images, SVGs, icons, lottie/animations, and asset path constants (no fonts, no widgets) | Active |
| `config` | Pure-Dart env constants, feature flags, API URLs | Active |
| `flavors` | Flavor definitions (dev/qa/stage/prod) | Active |
| `network` | Dio client, interceptors, token management | Active |
| `storage` | Hive encrypted cache, secure token storage | Active |
| `app_logger` | App-level logger + BLoC observer | Active |
| `utilities` | Date/string/number formatting helpers | Active |
| `testing` | Shared test utilities, fakes, matchers | Active |
| `maps` | Shared Google Maps widgets over `google_maps_flutter` | Active |
| `permissions` | Shared permission handling over `permission_handler` | Active |

### Domain / Data

| Package | Description | Status |
|---------|-------------|--------|
| `domain` | Shared business domain entities and contracts | Active |
| `shared_models` | Domain entities shared across apps | **Empty stub — overlaps `domain`; see Naming Recommendation below. No consumers, not deleted.** |
| `api` | Remote API layer (endpoints, DTOs, repos) | Stub |

### Features

| Package | Description | Status |
|---------|-------------|--------|
| `auth` | Login, logout, register, session, auth BLoC | Active (reference) |
| `otp` | OTP verification flow | Active |
| `forgot_password` | Password reset flow | Active |
| `change_password` | Authenticated password update | Stub |
| `branches` | Provider branch management | Active |

### UI / Localization

| Package | Description | Status |
|---------|-------------|--------|
| `design_system` | Theme, colors, typography, tokens, primitive components (`components/`), and higher-level composed UI (`shared_ui/`) | Active |
| `localization` | EasyLocalization, TranslateBloc, validation keys | Active |
| `shared_blocs` | Backwards-compat re-export facade | Active |

### Platform

| Package | Description | Status |
|---------|-------------|--------|
| `analytics` | Firebase Analytics + Crashlytics | Stub |
| `notifications` | Firebase Messaging + local notifications | Stub |

## Creating a New Package

1. **Infrastructure / shared:** Create `packages/<name>/` with `pubspec.yaml` (`publish_to: none`)
2. **Feature:** Use `melos run feature:create -- <name> shared` (creates `packages/features/<name>/`)
3. Add to root `pubspec.yaml` workspace list
4. Create `analysis_options.yaml` (include `very_good_analysis`)
5. Create `lib/<name>.dart` barrel file
6. Create `test/` folder
7. Run `melos bootstrap`
8. Add entry to this document

See `package_creation.skill.md` for detailed workflow.

## Dependency Rules

- Packages never import apps
- Direction: `apps → feature packages → design_system → app_assets / core`
- `design_system` must never depend on a feature package (verified — see `docs/DEPENDENCY_GRAPH.md`)
- No circular dependencies

## Removed Packages

- `dependencies` (centralized third-party re-export hub) — **deleted**, zero consumers verified. Import third-party packages directly instead.
- `settings` — **deleted**, dead stub (route constant only, zero imports anywhere). The real settings UI lives in `apps/sanad_provider/lib/src/features/settings/`.
- `shared_widgets` — **deleted**, dissolved into `design_system/components/` (primitives), `packages/features/otp` (OTP field), and `packages/features/branches` (branch widgets).

## Naming Recommendation: `shared_models` (Not Executed)

`packages/shared_models` currently has zero implementation (no `lib/` directory) and zero consumers, and its stated purpose duplicates `packages/domain`, which is active and already owns shared entities. Recommendation: either consolidate into `domain` and delete the stub, or — if a distinct serializable/transport DTO layer is genuinely wanted — rename it once it has real content (e.g. `api_models`) to signal that distinction. No rename or deletion has been performed; this is a documented finding awaiting a separate decision.
