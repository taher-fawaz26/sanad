# Sanad Architecture

> **Related:** [`ARCHITECTURE_BLUEPRINT.md`](ARCHITECTURE_BLUEPRINT.md) — pattern-level
> reference for error handling, network retries, offline behaviour, and API contracts.

## Overview

Sanad is a Flutter monorepo managed by Melos, containing two apps and 24+ shared packages. Business logic lives in packages; apps are thin shells handling routing, DI bootstrap, and app-specific UI pages.

## Monorepo Structure

```
sanad/
├── apps/
│   ├── sanad_client/        # Client-facing app (service consumers)
│   │   └── assets/          # icons/, images/, splash/ — app-owned only
│   └── sanad_provider/      # Provider-facing app (service providers)
│       └── assets/          # icons/, images/{branches,workers,splash}/
├── packages/
│   ├── core/                 # Failure, UseCase, DI base, validators
│   ├── app_assets/           # Shared images, SVGs, icons
│   ├── network/              # Dio, interceptors, error mapping
│   ├── storage/              # Secure storage, Hive cache
│   ├── design_system/        # Theme, tokens, components
│   ├── localization/         # EasyLocalization, TranslateBloc
│   └── features/             # Business feature packages
│       ├── auth/             # Authentication (reference impl)
│       ├── otp/              # OTP verification
│       ├── forgot_password/  # Password reset
│       ├── branches/         # Provider branches
│       └── ...               # See PACKAGE_GUIDE.md
└── pubspec.yaml               # Workspace root — `workspace:` list + `melos:` config
```

`packages/dependencies`, `packages/settings`, and `packages/shared_widgets` have been removed — see the Asset Ownership Policy, Component Ownership Policy, and Package Ownership Matrix below for where their responsibilities now live. Settings UI now lives in `packages/features/account_settings` (shared) and `packages/features/organization_settings` (provider-only).

## Clean Architecture Layers

Every feature package follows:

```
data/ → domain/ → presentation/ → di/ → routes/
```

| Layer | Responsibility | Imports |
|-------|---------------|---------|
| `domain/` | Entities, repo contracts, use cases | `core` only (no Flutter) |
| `data/` | DTOs, data sources, repo implementations | `domain/`, `network` |
| `presentation/` | BLoC, pages, widgets | `domain/`, `design_system` |
| `di/` | GetIt registrations | All layers |
| `routes/` | Route path constants | None |

## Dependency Direction

```
apps → feature packages → UI/infra packages → core
```

- Apps import packages — never the reverse
- No circular dependencies between packages
- Abstract contracts in `domain/`, implementations in `data/`

## App vs Feature Package

| Location | Contains | Example |
|----------|----------|---------|
| `apps/*/features/` | UI pages only | `branches_page.dart` |
| `packages/features/<feature>/` | Full clean arch | `packages/features/branches/` |

## Adding a New Feature

```
Does it have business logic?
├── Yes → Is it shared between apps?
│   ├── Yes → Create feature package under packages/features/
│   └── No → Consider feature package or app features/
└── No → App features/ folder (page only)
```

Reference implementation: `packages/features/auth/lib/src/`

## State Management

- **BLoC** (`flutter_bloc`) for feature logic
- **Cubit** for pure UI state only (no network)
- **HydratedBloc** for persistence (theme, locale)
- **TaskEither\<Failure, T\>** (fpdart) for all async results

## Asset Ownership Policy

Every asset file belongs to **exactly one** owner. Never duplicate an asset across locations — if a second consumer needs it, promote it to the shared tier.

| Tier | Owner | Rule |
|------|-------|------|
| Shared (2+ apps, or consumed by `design_system`) | `packages/app_assets/assets/` | Images under `images/{illustrations,empty_states,onboarding}/`, icons under `icons/`, SVGs under `svgs/`, Lottie under `lottie/`, motion under `animations/`. Loaded with `package: AppAssets.package` |
| Application (exactly one app) | `apps/<app>/assets/` | e.g. `apps/sanad_provider/assets/images/{branches,workers,splash}/`. Loaded with no `package:` argument |
| Feature (exactly one feature package) | `packages/features/<feature>/assets/` | Only if a feature package ships its own bundled asset; declare in that package's own `pubspec.yaml` |

Fonts are the one exception: they are a **Design Language / Typography System** concern, not a generic asset, and stay declared in `packages/design_system/pubspec.yaml` regardless of this tiering — never move fonts into `app_assets`.

`core` owns **zero** assets and zero asset path constants, by design. It is a pure foundation package.

## Component Ownership Policy

| Tier | Owner | Examples |
|------|-------|----------|
| Design Tokens | `design_system/lib/src/theme/tokens/` | `AppSpacing`, `AppRadius`, `AppShadows`, `ButtonTokens`, `OverlayTokens` |
| Primitive Components | `design_system/lib/src/components/` | `AppButton`, `AppTextField`, `AppAvatar`, `AppSvgPicture`, `AppCloseIcon`, `AppNotificationIcon` |
| Shared UI | `design_system/lib/src/shared_ui/` | `AppEntityListItem`, `AppEmptyState`, `AppConfirmationContent`, `AppSuccessPopover`, `AppProgressDialog` |
| Higher-Level Shared UI | `design_system/lib/src/shared_ui/` | `AppEmptyState`, `AppNetworkFailureState`, `AppNetworkErrorPage`, `AppSuccessPopover` / `showAppSuccessPopover`, `AppProgressDialog` / `showAppProgressDialog`, `AppGenericEmptyState` — composed from primitives + tokens, still domain-agnostic |
| Feature Widgets | `packages/features/<feature>/lib/src/presentation/widgets/` or `apps/<app>/lib/src/features/<feature>/widgets/` | `AppOtpField` (`packages/features/otp`), branch widgets (`packages/features/branches`) |

Feature widgets must **never** live inside `design_system` — even if they're built entirely from design-system primitives. The test: if the widget encodes knowledge of a specific feature/domain (OTP length, branch location, person selection), it belongs to that feature, not to `design_system`.

Dev-only preview/showcase widgets (`AppColorPalettePreview`, `AppTypographyPreview`) live in `design_system/lib/src/dev/` and are intentionally excluded from every barrel export — they're internal tooling, not public API.

## Package Ownership Matrix

| Package | Responsibility | Must NOT contain |
|---------|-----------------|-------------------|
| `core` | Foundation utilities — Failure, UseCase, DI base, validators, extensions | UI, Assets, Widgets |
| `app_assets` | Shared images, SVGs, icons, lottie/animations, and their path constants | Widgets, Theme, Fonts, Helpers |
| `design_system` | Design tokens, primitive components, higher-level shared UI | Business logic, Feature widgets |
| `network` | Dio client, interceptors, error mapping | UI |
| `storage` | Secure/local storage | Widgets |
| `auth` | Authentication feature (reference implementation) | Provider-specific or client-specific features |
| `otp` | OTP verification flow (including `AppOtpField`) | Shared business logic unrelated to OTP |
| `localization` | EasyLocalization setup, translation keys, TranslateBloc | UI components |
| `domain` | Shared business entities and repository contracts | Flutter/UI, data sources |
| `api` | Remote API layer (endpoints, DTOs, repos) | UI |
| `apps/*` | App composition, routing, DI bootstrap, app-specific pages | Shared business components, shared design-system primitives |

## Architecture Decision Tree

Every new reusable item must answer this before it gets a home:

```
Is it an asset (image, SVG, icon, lottie, animation)?
├── Yes → shared by 2+ apps or by design_system?
│   ├── Yes → packages/app_assets/
│   └── No  → owned by exactly one app?
│       ├── Yes → apps/<app>/assets/
│       └── No  → owned by exactly one feature package → packages/features/<feature>/assets/
└── No → Is it a font?
    └── Yes → packages/design_system/ (fonts stay with Typography, never app_assets)

Is it a visual UI component?
├── Yes → is it a primitive (no domain/business knowledge)?
│   ├── Yes → design_system/lib/src/components/
│   └── No  → is it still domain-agnostic, just composed from primitives?
│       ├── Yes → design_system/lib/src/shared_ui/
│       └── No  → it encodes feature/domain knowledge → owning feature package or app

Is it business logic (BLoC, UseCase, Repository, data source)?
└── Yes → feature package (packages/features/<feature>/), following data/ → domain/ → presentation/ → di/ → routes/

Is it application-specific (routing glue, app-only page, app DI bootstrap)?
└── Yes → apps/<app>/lib/src/
```

## Naming Recommendation: `shared_models`

`packages/shared_models` has zero implementation (no `lib/` source beyond scaffolding) and zero consumers today. Its stated purpose — domain entities shared across apps — already overlaps `packages/domain`, which is active. Two options, neither executed yet (decision deferred to the team):

1. Consolidate: delete the `shared_models` stub and treat `domain` as the single home for shared entities.
2. Differentiate: if a distinct transport/serialization DTO layer is genuinely needed (as opposed to domain entities), rename it to something that signals that distinction (e.g. `api_models`) once it has real content.

Do not add new code to `shared_models` until this is resolved.

## Key Decisions

- GetIt for DI (`sl` service locator)
- GoRouter for navigation
- EasyLocalization for i18n (Arabic default, RTL first)
- ScreenUtil for responsive layout (360×800 design size)
