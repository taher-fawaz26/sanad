# ADR-0006: BLoC State Management

**Date:** 2025-06-01  
**Status:** Accepted  
**Deciders:** Platform Architecture Team

## Context

Network/async UI state requires predictable event→state transitions. `setState` and ad-hoc callbacks caused untestable presentation logic and inconsistent loading/error handling.

## Decision

Use `flutter_bloc` for all network/async state:
- One BLoC per feature flow
- Sealed event/state hierarchies
- UseCases injected via constructor (not service locator inside BLoC)
- `BlocConsumer` / `BlocBuilder` in pages — never `setState` for async state
- `packages/shared_blocs` for cross-app blocs (e.g. locale, theme)

## Consequences

### Positive
- Testable with `bloc_test`
- Clear state machine per feature
- Consistent loading/success/failure patterns

### Negative
- Boilerplate (event/state/bloc files)
- Not ideal for ephemeral UI-only state (use `HookWidget` local state)

### Risks
- God BLoCs — mitigated by one-BLoC-per-flow rule

## Alternatives Considered

| Option | Reason rejected |
|--------|----------------|
| Riverpod | Team familiarity with BLoC; existing investment |
| ChangeNotifier | No built-in event testing; less structured |
| Redux | Excessive ceremony for mobile feature scope |

## Links

- `.cursor/rules/bloc.mdc`
- ADR-0002 (Clean Architecture)
