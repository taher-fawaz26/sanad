---
name: architecture
description: Clean architecture reference — layer ownership, dependency direction, package decisions
---

# Architecture Skill

Reference for clean architecture decisions in the Sanad monorepo.

## Layer Ownership

| Layer | Owns | Location |
|-------|------|----------|
| Domain | Entities, repo contracts, use cases | `packages/<feature>/lib/src/domain/` |
| Data | DTOs, data sources, repo impls | `packages/<feature>/lib/src/data/` |
| Presentation | BLoC, pages, widgets | `packages/<feature>/lib/src/presentation/` |
| DI | GetIt registrations | `packages/<feature>/lib/src/di/` |
| Routes | Path constants | `packages/<feature>/lib/src/routes/` |

## Dependency Direction

```
apps (sanad_client, sanad_provider)
  ↓
feature packages (auth, otp, forgot_password)
  ↓
UI packages (design_system, shared_widgets, localization)
  ↓
infra packages (network, storage, api)
  ↓
core (Failure, UseCase, DI base, validators)
```

## When to Create a New Package

- Feature has its own domain logic, API endpoints, and BLoC
- Feature is shared between client and provider apps
- Feature has 3+ use cases

## When NOT to Create a New Package

- Single page with no business logic → app `features/` folder
- Simple utility → add to `core` or `utilities`
- UI-only composite widget → `shared_widgets`

## Decision Tree

```
New functionality needed?
├── Shared between apps?
│   ├── Has business logic? → New feature package
│   └── UI only? → shared_widgets or design_system
└── App-specific?
    ├── Has business logic? → Consider feature package
    └── UI page only? → apps/<app>/lib/src/features/
```

## Reference Implementation

`packages/auth/` is the canonical example of clean architecture in this monorepo.
