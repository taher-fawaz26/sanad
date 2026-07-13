# ADR-0004: Asset Ownership (app_assets)

**Date:** 2026-03-01  
**Status:** Accepted  
**Deciders:** Platform Architecture Team

## Context

Assets were previously scattered across `packages/core` and `packages/shared_widgets`, coupling infrastructure to UI resources and making ownership unclear.

## Decision

Split asset ownership:
- **`packages/app_assets`** — shared SVGs, empty-state images, path constants (`AppAssets`, `AppSvgs`, `AppImages`). No fonts, no widgets.
- **`packages/design_system`** — fonts, all UI components
- **`apps/*/assets/`** — app-specific images only

`packages/core` owns zero UI/asset knowledge.

## Consequences

### Positive
- Clear dependency graph: `app_assets` and `core` are independent roots
- Features import assets without pulling widgets
- App-specific branding stays in app folders

### Negative
- Developers must know which package owns which asset type

### Risks
- Assets placed in wrong package — mitigated by `.cursor/rules/assets.mdc`

## Alternatives Considered

| Option | Reason rejected |
|--------|----------------|
| All assets in design_system | Forces Flutter dep for path constants only |
| All assets in core | Violates core purity; core had no UI role |

## Links

- `docs/ARCHITECTURE.md`
- ADR-0003 (Design Tokens)
