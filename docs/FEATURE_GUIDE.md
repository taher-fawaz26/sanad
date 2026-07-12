# Feature Guide

## Feature Package Structure

Reference implementation: `packages/auth/`

```
packages/<feature>/lib/src/
├── data/
│   ├── datasources/       # API/Hive data sources
│   ├── models/            # DTOs with fromJson/toJson
│   └── repositories/      # Repository implementations
├── domain/
│   ├── entities/          # Business entities (Equatable)
│   ├── repositories/      # Abstract repository contracts
│   └── usecases/          # UseCase implementations
├── presentation/
│   ├── bloc/              # BLoC, events, states
│   ├── pages/             # Screen widgets
│   └── widgets/           # Feature-specific widgets
├── di/
│   └── <feature>_di.dart  # GetIt registrations
└── routes/
    └── <feature>_routes.dart  # Route path constants
```

## App Features vs Feature Packages

| Type | Location | Contains | Example |
|------|----------|----------|---------|
| Feature Package | `packages/<name>/` | Full clean arch | `auth`, `otp` |
| App Feature | `apps/*/features/` | UI page only | `branches_page.dart` |

App features are thin UI shells. Business logic must live in packages.

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

## Creating a New Feature

See `feature.skill.md` for the complete step-by-step workflow.

## Localization

All feature strings use `'feature.key'.tr()` with keys in both `ar-AR.json` and `en-US.json`.
