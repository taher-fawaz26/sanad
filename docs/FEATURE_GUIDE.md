# Feature Guide

Canonical structure, naming conventions, and layer rules for every feature package in the Sanad monorepo.

**Reference implementation:** `packages/auth/`

---

## Feature Package Structure

```
packages/<feature>/
├── pubspec.yaml
├── analysis_options.yaml
├── README.md
├── lib/
│   ├── <feature>.dart                  # Barrel export (public API only)
│   └── src/
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── <feature>_remote_datasource.dart
│       │   │   └── <feature>_local_datasource.dart   # optional
│       │   ├── models/
│       │   │   ├── requests/                         # request DTOs
│       │   │   └── <feature>_response_model.dart     # response DTOs
│       │   ├── repositories/
│       │   │   └── <feature>_repository_impl.dart
│       │   └── endpoints/
│       │       └── <feature>_api_paths.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── <feature>_entity.dart
│       │   ├── repositories/
│       │   │   └── <feature>_repository.dart           # abstract contract
│       │   └── usecases/
│       │       ├── <feature>_params.dart
│       │       └── <action>_usecase.dart               # one file per action
│       ├── presentation/
│       │   ├── bloc/
│       │   │   ├── <feature>_bloc.dart
│       │   │   ├── <feature>_event.dart
│       │   │   └── <feature>_state.dart
│       │   ├── pages/
│       │   │   └── <feature>_page.dart
│       │   └── widgets/                               # optional
│       ├── di/
│       │   └── <feature>_di.dart
│       ├── routes/
│       │   └── <feature>_routes.dart
│       └── module/
│           └── <feature>_module.dart                  # FeatureModule impl
├── assets/                                            # optional
└── test/
    └── src/
        ├── data/
        ├── domain/
        └── presentation/
```

---

## App Features vs Feature Packages

| Type | Location | Contains | Example |
|------|----------|----------|---------|
| Feature Package | `packages/<name>/` | Full clean arch | `auth`, `otp` |
| App Feature | `apps/*/lib/src/features/` | UI page only | `branches_page.dart` |

App features are thin UI shells. Business logic must live in packages.

---

## Naming Conventions

| Type | Convention | Example |
|------|-----------|---------|
| Package | `snake_case` | `orders`, `branch_workers` |
| Files | `<feature>_<role>.dart` | `orders_bloc.dart` |
| Classes — BLoC | `<Feature>Bloc` | `OrdersBloc` |
| Classes — UseCase | `<Verb><Feature>UseCase` | `FetchOrdersUseCase` |
| Classes — Repository (abstract) | `<Feature>Repository` | `OrdersRepository` |
| Classes — Repository impl | `<Feature>RepositoryImpl` | `OrdersRepositoryImpl` |
| Classes — DataSource (abstract) | `<Feature>RemoteDataSource` | `OrdersRemoteDataSource` |
| Classes — DataSource impl | `<Feature>RemoteDataSourceImpl` | `OrdersRemoteDataSourceImpl` |
| Classes — DI | `<Feature>DI` | `OrdersDI` |
| Classes — Module | `<Feature>Module` | `OrdersModule` |
| Route constants | `<Feature>Routes` | `OrdersRoutes` |
| Request DTOs | `<Action><Feature>Request` | `CreateOrderRequest` |
| Response DTOs | `<Feature>Response` | `OrderResponse` |
| Entities | `<Feature>Entity` | `OrderEntity` |
| Params | `<UseCase>Params` | `FetchOrdersParams` |

---

## Layer Dependency Rules

| Layer | May import | Must NOT import |
|-------|-----------|-----------------|
| `domain/` | `core` only | `data/`, `presentation/`, Flutter SDK |
| `data/` | `domain/`, `network`, `storage`, `core` | `presentation/` |
| `presentation/` | `domain/`, `design_system`, `localization`, `core` | Direct Dio/repo impls |
| `di/` | All layers | — |
| `routes/` | `presentation/` pages only | `data/` |
| `module/` | `di/`, `routes/`, `presentation/` | — |

---

## Required vs Optional Files

**Required:** `pubspec.yaml`, `analysis_options.yaml`, `lib/<feature>.dart`, `<feature>_repository.dart`, `<feature>_repository_impl.dart`, `<feature>_remote_datasource.dart`, `<feature>_bloc.dart`, `<feature>_event.dart`, `<feature>_state.dart`, `<feature>_di.dart`, `<feature>_routes.dart`, `<feature>_module.dart`

**Optional:** local datasource, widgets folder, assets folder

---

## Public API (Barrel) Rules

- Export only what consumers need — hide `*_impl.dart` unless DI requires it
- Never export internal helpers from `lib/src/**/internal/`
- Cross-package imports must use the barrel: `import 'package:auth/auth.dart'`
- Never bypass the barrel: `import 'package:auth/src/data/...'` ❌

---

## Routing Convention

```dart
abstract final class FeatureRoutes {
  static const String list = '/feature';
  static const String detail = '/feature/:id';
}
```

Typed extras for routes needing arguments:

```dart
context.push(OtpRoutes.verify, extra: OtpArgs(phone: phone));
```

---

## Feature Module Registration

Shared feature packages implement `FeatureModule` from `core`:

```dart
final modules = [
  AuthModule(),
  OtpModule(),
  ForgotPasswordModule(),
];
await ModuleRegistry(modules).initAll();
```

Adding a new shared feature requires **one line** in the app's module list.

---

## Localization

All feature strings use `'feature.key'.tr()` with keys in both `ar-AR.json` and `en-US.json`.

---

## Creating a New Feature

```bash
# Shared feature package (full clean arch)
melos feature:create orders --shared

# Provider app UI-only feature
melos feature:create branches --app provider

# Client app UI-only feature
melos feature:create profile --app client

# App feature with backend package
melos feature:create branches --app provider --with-backend
```

See `.cursor/skills/create_feature.skill.md` for the complete workflow.

---

## Active Feature Packages

| Package | Routes | BLoC | Status |
|---------|--------|------|--------|
| `auth` | `/`, `/login`, `/register` | `AuthBloc` | Active |
| `otp` | `/otp` | `OtpBloc` | Active |
| `forgot_password` | `/forgot-password`, `/forgot-password/reset` | `ForgotPasswordBloc` | Active |

## App Features (Provider)

| Feature | Routed | Files |
|---------|--------|-------|
| home | Yes (`/home`) | `home_page.dart` |
| requests | Yes (`/requests`) | `requests_page.dart` |
| messages | Yes (`/messages`) | `messages_page.dart` |
| settings | Yes (`/settings`) | `settings_page.dart` |
| branches | Yes (`/branches`, `/branches/add`) | `branches_page.dart`, `add_branch_page.dart` |
| availability | No | `availability_page.dart` |
| schedule | No | `schedule_page.dart` |
| services | No | `services_page.dart` |
| profile | No | `profile_page.dart` |
