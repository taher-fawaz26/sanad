# ADR-0007: GoRouter Navigation

**Date:** 2025-07-01  
**Status:** Accepted  
**Deciders:** Platform Architecture Team

## Context

Navigator 1.0 imperative API made deep linking, auth redirects, and shell navigation (bottom tabs) difficult to maintain across two apps.

## Decision

Use `go_router` for all navigation:
- Route path constants in feature packages (`AuthRoutes`, `OtpRoutes`)
- `GoRouter` with `refreshListenable` tied to `AuthStatusNotifier`
- `ShellRoute` for auth BLoC providers and tab shells
- Typed `extra` arguments for routes needing data (`OtpArgs`, etc.)
- Feature modules contribute routes via `FeatureModule` (see Phase 8)

## Consequences

### Positive
- Declarative route tree
- Deep link support
- Auth redirect in one place

### Negative
- Route definitions can grow large — mitigated by FeatureModule
- `extra` is untyped at router level — use redirect guards

### Risks
- Breaking deep links on route changes — document in feature CHANGELOG

## Alternatives Considered

| Option | Reason rejected |
|--------|----------------|
| auto_route | Code generation overhead; build_runner in CI |
| Navigator 2.0 raw | Too verbose; go_router wraps it cleanly |
| Beamer | Smaller ecosystem; less team familiarity |

## Links

- `docs/ROUTING.md`
- ADR-0008 (GetIt DI)
