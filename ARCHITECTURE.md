# Sanad Monorepo — Architecture

> **Version:** 3.0
> **Last updated:** 2026-07-10
> **Status:** Production

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Directory Structure](#2-directory-structure)
3. [Package Responsibilities](#3-package-responsibilities)
4. [Application Responsibilities](#4-application-responsibilities)
5. [Dependency Graph](#5-dependency-graph)
6. [Why shared\_features Was Removed](#6-why-shared_features-was-removed)
7. [Why Profile Is Application-Specific](#7-why-profile-is-application-specific)
8. [Melos Commands](#8-melos-commands)
9. [CI Workflow](#9-ci-workflow)
10. [Package Naming Conventions](#10-package-naming-conventions)
11. [Migration Summary](#11-migration-summary)

---

## 1. Project Overview

**Sanad** is a Flutter monorepo powering two distinct mobile applications:

| App | Package | Audience |
|-----|---------|----------|
| Sanad Client | `sanad_client` | End-users booking services |
| Sanad Provider | `sanad_provider` | Service providers managing bookings |

The monorepo is managed with [Melos](https://melos.invertase.dev/) and follows a layered, clean-architecture approach. Shared infrastructure lives in standalone packages under `packages/`; application-specific logic lives inside each app's own `lib/src/features/` directory.

---

## 2. Directory Structure

```
sanad/                          ← workspace root (name: sanad in melos.yaml)
├── apps/
│   ├── sanad_client/           ← Client application
│   └── sanad_provider/         ← Provider application
├── packages/
│   ├── analytics/              ← Firebase Analytics + Crashlytics
│   ├── api/                    ← Generated API clients / DTOs
│   ├── app_logger/             ← Structured logging (wraps logger)
│   ├── assets/                 ← Raw asset files (images, icons, fonts stub)
│   ├── auth/                   ← Auth BLoC, pages, domain, data, DI
│   ├── config/                 ← Environment config (base URLs, feature flags)
│   ├── core/                   ← Service locator, failures, use-case base
│   ├── dependencies/           ← Third-party dependency stubs (DI wiring)
│   ├── design_system/          ← Theme, typography, shared widgets, fonts
│   ├── domain/                 ← Shared entities, repository contracts
│   ├── flavors/                ← Flavor definitions (dev/staging/prod)
│   ├── localization/           ← easy_localization setup, translation files
│   ├── network/                ← Dio client, interceptors, token refresh
│   ├── notifications/          ← Firebase Messaging + local notifications
│   ├── storage/                ← Hive CE + flutter_secure_storage wrappers
│   ├── testing/                ← Shared test utilities, mocks, fakes
│   └── utilities/              ← Pure-Dart helpers (extensions, validators)
├── .github/
│   └── workflows/              ← CI: analyze, test, coverage, release
├── melos.yaml
└── pubspec.yaml                ← Workspace root (no deps — packages only)
```

---

## 3. Package Responsibilities

### `core`
The foundation of the monorepo. Provides:
- `ServiceLocator` (`get_it` wrapper, `sl<T>()`)
- `SessionManager` — token storage and session lifecycle
- `Failure` hierarchy used by all use cases
- `UseCase<T, P>` / `NoParamsUseCase<T>` base classes (fpdart `TaskEither`)
- `AppLocaleRefreshBus` — event bus for locale changes

**Depended on by:** almost every other package.

### `domain`
Shared business entities and repository contracts that span both applications:
- `UserEntity`, `ServiceEntity`, `BookingEntity`, …
- Repository interfaces (implemented in `network` / `storage`)

### `network`
HTTP layer:
- `DioClient` factory with auth interceptor and token-refresh logic
- `NetworkInfo` / connectivity check
- Error parsing into `Failure` types
- `ApiInterceptor`, `LoggingInterceptor`

### `auth`
Complete authentication vertical:
- **Domain**: `LoginUseCase`, `LogoutUseCase`, `CheckSignInStatusUseCase`, OTP / forgot-password use cases
- **Data**: `AuthRemoteDatasource`, `AuthLocalDatasource`, `AuthRepositoryImpl`
- **Presentation**: `AuthBloc` (with `AuthEvent` / `AuthState` parts), `LoginPage`, `SplashPage`
- **DI**: `AuthDI.init()` registers all auth dependencies
- **Routes**: `AuthRoutes` constants

`LoginPage` and `SplashPage` live here so both apps share the same auth UI without a shared-features layer.

### `storage`
Persistence primitives:
- Hive CE box registration and typed adapters
- `SecureStorage` wrapper (flutter_secure_storage)
- `TokenManager` — access/refresh token read/write

### `design_system`
Visual language:
- `SanadTheme` (light/dark `ThemeData`)
- Typography (Poppins + NotoSansArabic, 4 weights each)
- Reusable widgets: `SanadButton`, `SanadTextField`, loading overlays
- Screen-utility extensions

### `localization`
Internationalisation:
- `easy_localization` bootstrap
- Translation JSON files under `assets/translations/`
- `AppLocalizations` convenience wrapper

### `config`
Runtime configuration:
- `AppConfig` (baseUrl, apiKey, environment)
- Loaded before `runApp()` from JSON / env

### `flavors`
Flavor definitions (`dev`, `staging`, `prod`) and `FlavorConfig` accessor.

### `analytics`
Firebase Analytics event tracking and Crashlytics crash reporting.

### `notifications`
Firebase Cloud Messaging setup, foreground/background notification handling, and `flutter_local_notifications` integration.

### `app_logger`
Structured logging wrapper around the `logger` package, initialised via `AppLoggerDI`.

### `api`
Generated API client stubs and request/response DTOs. Updated by `melos run generate`.

### `assets`
Raw asset files (splash images, icons) referenced by apps through their own `pubspec.yaml`.

### `testing`
Dev-only shared test utilities:
- `MockAuthRepository`, `FakeUserEntity`, BLoC test helpers
- Widget pump helpers (`pumpApp`)
- Common matchers

### `utilities`
Pure-Dart extensions, validators, and formatters with no Flutter dependency.

### `dependencies`
Registers third-party dependencies (get_it registration helpers used during DI bootstrap).

---

## 4. Application Responsibilities

### `sanad_client`
Audience: end-users.

Features owned by this app (under `lib/src/features/`):
| Feature | Description |
|---------|-------------|
| `home` | Client home dashboard |
| `booking` | Browse and book services |
| `orders` | Order history and status |
| `offers` | Promotional offers |
| `services` | Service catalogue |
| `favorites` | Saved services |
| `wallet` | Payment wallet |
| `support` | In-app support / chat |
| `profile` | **Client-specific** profile — name, phone, address, payment methods |

Bundle ID: `com.sanad.client`

### `sanad_provider`
Audience: service providers.

Features owned by this app (under `lib/src/features/`):
| Feature | Description |
|---------|-------------|
| `home` | Provider home dashboard |
| `orders` | Incoming booking requests |
| `schedule` | Availability calendar |
| `availability` | On/off-duty toggle |
| `customers` | Customer list |
| `statistics` | Revenue and rating stats |
| `wallet` | Earnings wallet |
| `support` | Provider support |
| `profile` | **Provider-specific** profile — service areas, pricing, certifications |

Bundle ID: `com.sanad.provider`

---

## 5. Dependency Graph

```
sanad_client / sanad_provider
        │
        ├─► auth          ─► core, network, storage
        ├─► design_system ─► (none)
        ├─► localization  ─► (none)
        ├─► network       ─► core
        ├─► storage       ─► core
        ├─► app_logger    ─► core
        └─► core
                │
                └─► (leaf — no monorepo deps)
```

All packages are **strictly layered** — no upward dependencies (packages do not import apps). Cross-package imports use `package:` URIs enforced by the `always_use_package_imports` lint rule.

---

## 6. Why `shared_features` Was Removed

`packages/shared_features/` was an intermediate aggregation layer (`auth`, `change_password`, `forgot_password`, `otp`, `settings`, `notifications`, `profile`) that added indirection without benefit:

- Each sub-package was a thin wrapper that re-exported an identically named standalone package.
- It created an extra pubspec dependency chain: apps → shared_features/auth → auth → core.
- When the standalone package changed, both the standalone package and the shared_features wrapper had to be updated.
- It obscured the actual dependency graph, making it harder to reason about what each app actually used.

**Resolution:** All standalone packages (`auth`, `notifications`, etc.) are imported directly by the apps. The wrapper layer is gone.

---

## 7. Why Profile Is Application-Specific

A shared `profile` package was rejected because the two apps have fundamentally different profile data:

| Field | Client | Provider |
|-------|--------|----------|
| Full name | ✓ | ✓ |
| Phone | ✓ | ✓ |
| Delivery address | ✓ | ✗ |
| Payment methods | ✓ | ✗ |
| Service areas | ✗ | ✓ |
| Pricing / rates | ✗ | ✓ |
| Certifications | ✗ | ✓ |
| Availability toggle | ✗ | ✓ |

Forcing a shared model would require either a fat entity with nullable fields (fragile) or an abstract base with two diverging implementations (defeating the point of sharing). Each app owns its own `features/profile/` instead.

Shared profile-related types (e.g. `UserEntity`) live in `domain`; shared UI atoms (avatar, form fields) live in `design_system`.

---

## 8. Melos Commands

```bash
# Bootstrap all packages (run after git clone or adding a new package)
melos bootstrap

# Analyze all packages
melos run analyze

# Run all tests with coverage
melos run test

# Format code (CI — fails if files need formatting)
melos run format

# Apply formatting
melos run format:fix

# Run code generation (build_runner) in all packages
melos run generate

# Generate localization files
melos run l10n

# Clean all packages
melos run clean

# Build release APK — client
melos run build:client:android

# Build release IPA — client
melos run build:client:ios

# Build release APK — provider
melos run build:provider:android

# Full quality gate (format + analyze + test)
melos run check

# CI entry-point
melos run ci
```

---

## 9. CI Workflow

| Workflow | Trigger | Steps |
|----------|---------|-------|
| `analyze.yml` | PR, push to main | `melos bootstrap` → `dart analyze --fatal-infos` on all packages |
| `test.yml` | PR, push to main | `melos bootstrap` → `flutter test --coverage` on all packages |
| `coverage.yml` | Push to main | Tests → LCOV report → Codecov upload |
| `release.yml` | Tag `v*` | Bootstrap → build `sanad_client` APK+AAB → build `sanad_provider` APK+AAB → upload artifacts |

---

## 10. Package Naming Conventions

| Rule | Example |
|------|---------|
| No project prefix on package names | `auth` not `sanad_auth` |
| `lowercase_snake_case` for all package names | `design_system`, `app_logger` |
| Barrel file matches package name | `packages/auth/lib/auth.dart` |
| `library` declaration in barrel | `library auth;` |
| Internal `src/` imports use `package:` URI | `package:auth/src/presentation/bloc/auth/auth_bloc.dart` |
| Public surface exported from barrel only | consumers import `package:auth/auth.dart` |

---

## 11. Migration Summary

This document reflects the **v3.0** architecture. Changes from v2.0:

| Change | Before | After |
|--------|--------|-------|
| Project name | Sand | Sanad |
| App bundle IDs | `com.sand.client` / `com.sand.provider` | `com.sanad.client` / `com.sanad.provider` |
| App package names | `sand_client` / `sand_provider` | `sanad_client` / `sanad_provider` |
| Package naming | `sand_core`, `sand_auth`, … | `core`, `auth`, … |
| Shared features layer | `packages/shared_features/{auth,otp,…}` | Removed — use packages directly |
| Shared profile package | `packages/profile` | Removed — each app owns `features/profile/` |
| Auth pages | In `shared_features/auth` | In `packages/auth/src/presentation/pages/` |
| Melos workspace name | `name: sand` | `name: sanad` |
| Package glob in melos.yaml | `packages/**` (picked up deleted packages) | Explicit list of active packages only |
