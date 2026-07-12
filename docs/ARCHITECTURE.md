# Sanad Architecture

## Overview

Sanad is a Flutter monorepo managed by Melos, containing two apps and 24+ shared packages. Business logic lives in packages; apps are thin shells handling routing, DI bootstrap, and app-specific UI pages.

## Monorepo Structure

```
sanad/
├── apps/
│   ├── sanad_client/      # Client-facing app (service consumers)
│   └── sanad_provider/    # Provider-facing app (service providers)
├── packages/
│   ├── core/                # Failure, UseCase, DI base, validators
│   ├── network/             # Dio, interceptors, error mapping
│   ├── storage/             # Secure storage, Hive cache
│   ├── design_system/       # Theme, tokens, UI components
│   ├── shared_widgets/      # Composite domain-aware widgets
│   ├── localization/        # EasyLocalization, TranslateBloc
│   ├── auth/                # Authentication feature (reference impl)
│   ├── otp/                 # OTP verification
│   ├── forgot_password/     # Password reset
│   └── ...                  # See PACKAGE_GUIDE.md
├── melos.yaml
└── pubspec.yaml             # Workspace root
```

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
| `packages/<feature>/` | Full clean arch | `packages/auth/` |

## Adding a New Feature

```
Does it have business logic?
├── Yes → Is it shared between apps?
│   ├── Yes → Create feature package under packages/
│   └── No → Consider feature package or app features/
└── No → App features/ folder (page only)
```

Reference implementation: `packages/auth/lib/src/`

## State Management

- **BLoC** (`flutter_bloc`) for feature logic
- **Cubit** for pure UI state only (no network)
- **HydratedBloc** for persistence (theme, locale)
- **TaskEither\<Failure, T\>** (fpdart) for all async results

## Key Decisions

- GetIt for DI (`sl` service locator)
- GoRouter for navigation
- EasyLocalization for i18n (Arabic default, RTL first)
- ScreenUtil for responsive layout (360×800 design size)
