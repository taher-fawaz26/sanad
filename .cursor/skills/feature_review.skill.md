---
name: feature_review
description: Review a complete feature package — all layers, DI, routes, localization, tests
---

# Feature Review Skill

Review a complete feature package for compliance.

## Domain Layer

- [ ] Entities extend `Equatable`
- [ ] Repository is abstract interface in `domain/repositories/`
- [ ] Use cases implement `UseCase<TResult, Params>`
- [ ] Use cases return `TaskEither<Failure, T>`
- [ ] Zero Flutter imports in `domain/`

## Data Layer

- [ ] DTOs have `fromJson`/`toJson` in `data/models/`
- [ ] Repository impl in `data/repositories/`
- [ ] Data sources in `data/datasources/`
- [ ] No direct Dio usage — via `ApiClientImpl`
- [ ] DTOs map to entities via `toEntity()`

## Presentation Layer

- [ ] BLoC follows naming: `<Feature>Bloc`, `<Feature><Action>Event`, `<Feature><Status>State`
- [ ] No business logic in widgets/pages
- [ ] `BlocBuilder`/`BlocListener` correctly scoped
- [ ] Pages use DS components only

## DI

- [ ] All classes registered in `di/<name>_di.dart`
- [ ] `<Name>DI.init()` called from app `app_di.dart`
- [ ] BLoCs as factories, repos/use cases as lazy singletons

## Routes

- [ ] `<Feature>Routes` class with `static const` paths
- [ ] Typed extras for routes needing arguments
- [ ] Registered in app router (`buildProviderRouter` / `buildClientRouter`)

## Localization

- [ ] All UI strings use `'key'.tr()`
- [ ] Keys in both `ar-AR.json` and `en-US.json`
- [ ] Validation uses `ValidationMessageKeys.*`
- [ ] Errors use `ErrorMessages.*`

## Testing

- [ ] Use case unit tests with `FakeRepository`
- [ ] BLoC tests with `bloc_test`
- [ ] Repository tests via `TaskEither.run()`
- [ ] 80% coverage for domain/data

## Architecture Compliance

- [ ] Dependency direction correct
- [ ] No circular deps
- [ ] No app imports from package
- [ ] No `domain/` importing `data/` or `presentation/`

## Design System Compliance

- [ ] No raw colors, typography, spacing
- [ ] DS components used throughout
- [ ] Composite widgets in `shared_widgets` if needed

## Output

Compliance score per section + list of violations with fixes.
