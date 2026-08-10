---
name: dependency_review
description: Review dependency architecture — circular deps, direction, layer violations
---

# Dependency Review Skill

Review package dependency architecture.

## Circular Dependency Detection

1. Read all `pubspec.yaml` files in workspace
2. Build dependency graph
3. Check for cycles: A → B → C → A

```bash
# Surface issues
melos analyze  # only when explicitly requested
```

## Dependency Direction Validation

Expected direction:
```
apps → feature packages → UI/infra packages → core
```

Flag any reverse dependency:
- Package importing an app
- `core` importing a feature package
- `domain` importing `data` or `presentation`

## Layer Violations

Per feature package:
- [ ] `domain/` has zero Flutter imports
- [ ] `domain/` does not import `data/`
- [ ] `data/` does not import `presentation/`
- [ ] `presentation/` does not import Dio or repository implementations

## Package Ownership

- [ ] Each package owns one domain concern
- [ ] No cross-domain logic leakage
- [ ] `settings` package not depended upon (orphaned)

## Clean Architecture Checklist

Per feature package (`auth`, `otp` as reference):
- [ ] `domain/repositories/` — abstract contracts only
- [ ] `domain/usecases/` — one use case per action
- [ ] `data/repositories/` — implementations only
- [ ] `data/datasources/` — API/Hive access only
- [ ] `di/` — all registrations in one file
- [ ] `routes/` — path constants only

## Package Graph Review

Compare actual `pubspec.yaml` deps against `docs/DEPENDENCY_GRAPH.md`.
Update diagram if discrepancies found.

## Output

Mermaid diagram of actual dependencies + list of violations with severity.
