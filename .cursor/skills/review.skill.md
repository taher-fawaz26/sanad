---
name: review
description: Comprehensive code review — architecture, performance, DS compliance, localization, BLoC, tests
---

# Review Skill

Perform a structured review of code changes in the Sanad monorepo.

## 1. Architecture Review

- [ ] Dependency direction correct: `apps → features → infra → core`
- [ ] No circular dependencies between packages
- [ ] Business logic in packages, not apps
- [ ] Clean arch layers respected (domain/data/presentation/di/routes)
- [ ] Repository contracts in `domain/`, implementations in `data/`
- [ ] BLoC calls UseCase, not Repository directly

## 2. Design System Compliance

- [ ] No `Colors.*` or hex literals — uses `context.appColors.*`
- [ ] No raw `TextStyle` — uses `context.appTypography.*` or `AppFont.*`
- [ ] No raw `EdgeInsets` — uses `AppSpacing.*`
- [ ] Uses DS components (`AppButton`, `AppTextField`, etc.)
- [ ] Composite widgets in `shared_widgets`, not `design_system`

## 3. Localization

- [ ] No hardcoded UI strings — all use `'key'.tr()`
- [ ] Keys exist in both `ar-AR.json` and `en-US.json`
- [ ] Validation uses `ValidationMessageKeys.*`
- [ ] Errors use `ErrorMessages.*`

## 4. BLoC Correctness

- [ ] Naming: `<Feature>Bloc`, `<Feature><Action>Event`, `<Feature><Status>State`
- [ ] No `BuildContext` in BLoC
- [ ] UseCase called via `TaskEither` fold pattern
- [ ] `BlocProvider` at route level, not deep in widget tree

## 5. Performance

- [ ] `const` widgets where possible
- [ ] `ListView.builder` for lists > 3 items
- [ ] No unnecessary rebuilds (`BlocSelector` / `buildWhen`)
- [ ] Controllers disposed in `dispose()`

## 6. Test Coverage

- [ ] Use cases have unit tests
- [ ] BLoC has `bloc_test` tests
- [ ] 80% coverage target for domain/data layers

## Output Format

Report findings as: **Critical** / **Warning** / **Suggestion** with file path and fix recommendation.
