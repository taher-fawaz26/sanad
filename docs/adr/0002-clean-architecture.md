# ADR-0002: Clean Architecture per Feature

**Date:** 2025-06-01  
**Status:** Accepted  
**Deciders:** Platform Architecture Team

## Context

Features like auth, OTP, and forgot-password share patterns but must remain independently testable and deployable as packages. Business logic mixed into app code caused duplication between client and provider.

## Decision

Every feature lives in `packages/<feature>/` with strict layer separation:

```
data/ → domain/ → presentation/ → di/ → routes/
```

- `domain/` owns entities, repository contracts, use cases — no Flutter imports
- `data/` implements repositories, talks to `network` and `storage`
- `presentation/` owns BLoC and UI — never imports Dio or repo impls
- Apps contain UI-only pages for app-specific screens

Reference: `packages/auth/`

## Consequences

### Positive
- Testable domain layer without Flutter
- Clear dependency direction enforced by validators
- Features reusable across both apps

### Negative
- More files per feature than a flat structure
- Onboarding requires understanding layer rules

### Risks
- Layer violations without CI — mitigated by `melos validate:arch`

## Alternatives Considered

| Option | Reason rejected |
|--------|----------------|
| MVC in app folders | No reuse; logic duplicated per app |
| MVVM with ChangeNotifier | Inconsistent async handling; no established pattern |

## Links

- `docs/ARCHITECTURE.md`
- `docs/FEATURE_GUIDE.md`
- ADR-0006 (BLoC), ADR-0005 (TaskEither)
