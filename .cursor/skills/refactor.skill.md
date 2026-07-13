---
name: refactor
description: Safe refactoring — read, plan, edit, analyze, test; preserve public API
---

# Refactor Skill

Refactor code without breaking existing functionality.

## Process

1. **Read** — understand current implementation and all usages
2. **Plan** — identify what changes, what stays, what breaks
3. **Edit** — make changes in batches
4. **Analyze** — run analyzer on affected package(s) once at end
5. **Test** — run tests for affected package(s)

## Rules

- Preserve public API signatures unless explicitly instructed
- Never remove working code without instruction
- Prefer extending over replacing
- Extract duplicated code to shared package/helper
- One logical change per commit

## Safe Refactor Patterns

| Pattern | Safe When |
|---------|-----------|
| Rename private method | No external callers |
| Extract widget | Widget used in 2+ places |
| Move to shared package | No circular deps introduced |
| Split large file | Using `part` files, same public API |
| Add parameter with default | Backward compatible |

## Unsafe Patterns (Require Explicit Approval)

- Change public method signature
- Remove exported class/widget
- Change BLoC event/state names (breaks tests)
- Change route paths (breaks deep links)
- Change localization key names
