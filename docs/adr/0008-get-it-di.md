# ADR-0008: GetIt Dependency Injection

**Date:** 2025-06-01  
**Status:** Accepted  
**Deciders:** Platform Architecture Team

## Context

Constructor injection works within a feature but apps must wire dozens of singletons (Dio, storage, token manager, feature repos). Manual `new` in widgets is forbidden.

## Decision

Use `get_it` via `packages/core` `ServiceLocator` (`sl`):
- App bootstrap (`app_di.dart`) registers infrastructure singletons
- Feature packages expose `<Feature>DI.init()` for their registrations
- BLoCs registered as `registerFactory`; services as `registerLazySingleton`
- Feature modules consolidate DI via `FeatureModule.registerDependencies()`

Named Dio instances: `'authDio'` and `'rawDio'`.

## Consequences

### Positive
- Single composition root per app
- Testable via override registrations
- No code generation

### Negative
- Service locator anti-pattern if overused in domain
- Registration order matters for async init (TokenManager)

### Risks
- Hidden dependencies — mitigated by explicit DI classes per feature

## Alternatives Considered

| Option | Reason rejected |
|--------|----------------|
| injectable + build_runner | CI slowdown; generated files in git |
| Manual constructor injection only | Impractical for 20+ singletons at app root |
| Riverpod as DI | Chosen BLoC for state; mixing adds complexity |

## Links

- `apps/*/lib/src/di/app_di.dart`
- ADR-0002 (Clean Architecture)
