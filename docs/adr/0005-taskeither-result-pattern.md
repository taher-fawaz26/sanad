# ADR-0005: TaskEither Result Pattern

**Date:** 2025-06-15  
**Status:** Accepted  
**Deciders:** Platform Architecture Team

## Context

Async operations need consistent error handling from API through BLoC. Mixing exceptions, nullable returns, and custom `Result` types created unpredictable failure paths.

## Decision

Use `TaskEither<Failure, T>` from `fpdart` throughout the data layer:
- `BaseApiClient.request()` returns `TaskEither<Failure, T>`
- Repository methods return `TaskEither<Failure, T>`
- Use cases return `TaskEither<Failure, T>`
- BLoC calls `.run()` and folds into states

`Failure` is a sealed hierarchy in `packages/core`. `FailureMapper` in `network` maps `DioException` — never leaked to features.

## Consequences

### Positive
- Composable error chains via `flatMap`, `map`, `chainFirst`
- Type-safe failure handling
- No try/catch in domain layer

### Negative
- Learning curve for developers unfamiliar with functional patterns
- Verbose compared to async/await with exceptions

### Risks
- Developers bypassing TaskEither with raw Future — mitigated by API guide and import scanner

## Alternatives Considered

| Option | Reason rejected |
|--------|----------------|
| Custom `Result<T>` sealed class | Reinvents fpdart; less composable |
| Exceptions in domain | Untyped; hard to test; leaks infrastructure |
| `Future<Either>` without Task | No lazy evaluation; harder to chain |

## Links

- `docs/API_GUIDE.md`
- ADR-0002 (Clean Architecture)
