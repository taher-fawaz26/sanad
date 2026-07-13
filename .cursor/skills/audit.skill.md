---
name: audit
description: Full package audit — dependencies, dead code, missing tests, token gaps
---

# Audit Skill

Perform a comprehensive audit of a package or the entire monorepo.

## 1. Dependency Audit

- Read `pubspec.yaml` dependencies
- Verify dependency direction (no reverse imports)
- Check for circular dependencies
- Flag orphaned packages (e.g. `settings` not in workspace)
- Compare against `docs/DEPENDENCY_GRAPH.md`

## 2. Code Quality

- Search for `// TODO`, `throw UnimplementedError()`, `UnimplementedError`
- Search for `print(` statements
- Search for hardcoded strings (not `.tr()`)
- Search for `Colors.` and hex color literals
- Search for raw `EdgeInsets` and `TextStyle`

## 3. Architecture Compliance

Per feature package, verify:
- [ ] `domain/` has no Flutter imports
- [ ] `data/` does not import `presentation/`
- [ ] `presentation/` does not call Dio or repository impls directly
- [ ] `di/` registers all classes
- [ ] `routes/` defines path constants

## 4. Test Coverage

- [ ] `test/` folder exists
- [ ] Use case tests present
- [ ] BLoC tests present
- [ ] Repository tests present

## 5. Token Gaps

- Compare design tokens with `TypeScale`, `AppSpacing`, `AppShadows`
- Document known gaps (w500, empty space.json, empty shadow.json)

## Output

Structured report with severity levels and actionable fix list.
