# Architecture Decision Records

Lightweight documentation capturing the **why** behind major architecture decisions.

## Index

| ADR | Title | Status |
|-----|-------|--------|
| [0001](0001-monorepo-melos.md) | Monorepo with Melos | Accepted |
| [0002](0002-clean-architecture.md) | Clean Architecture per Feature | Accepted |
| [0003](0003-design-system-tokens.md) | Design Tokens as Source of Truth | Accepted |
| [0004](0004-asset-ownership.md) | Asset Ownership (app_assets) | Accepted |
| [0005](0005-taskeither-result-pattern.md) | TaskEither Result Pattern | Accepted |
| [0006](0006-bloc-state-management.md) | BLoC State Management | Accepted |
| [0007](0007-go-router.md) | GoRouter Navigation | Accepted |
| [0008](0008-get-it-di.md) | GetIt Dependency Injection | Accepted |

## When to Create an ADR

Create an ADR when:
- A new package or architectural layer is added
- A technology is chosen over a realistic alternative
- An existing decision is revisited or reversed
- A cross-cutting convention is established

Do **not** create an ADR for: routine features, UI changes, bug fixes, config tweaks.

## Process

1. Copy `0000-template.md` to `NNNN-short-title.md`
2. Fill in all sections
3. Include the ADR in the **same PR** as the architectural change
4. At least one senior reviewer must approve
5. Merged ADRs are never deleted — only superseded
6. Update this index

## Template

See [0000-template.md](0000-template.md).
