# ADR-0003: Design Tokens as Source of Truth

**Date:** 2025-08-15  
**Status:** Accepted  
**Deciders:** Platform Architecture Team, Design

## Context

Hardcoded colors, spacing, and typography caused visual inconsistency and made dark mode / RTL support fragile. Figma tokens existed but were not enforced in code.

## Decision

`packages/design_system` owns all visual primitives:
- Color tokens via `context.appColors`
- Spacing/radius via token classes in `src/theme/tokens/`
- Typography via `AppTypography` and responsive scales
- Components consume tokens only — no raw `Color(0x...)` in features

Fonts live in `design_system` (not `app_assets`). Shared SVGs/images live in `app_assets`.

## Consequences

### Positive
- Single place to update visual language
- Dark/light themes stay synchronized
- Design catalog can showcase all components

### Negative
- New visual values require token addition before use
- `FieldTokens` exported for cross-package field styling (e.g. OTP)

### Risks
- Token sprawl — mitigated by design review and catalog policy

## Alternatives Considered

| Option | Reason rejected |
|--------|----------------|
| Per-app theming | Duplication; drift between client and provider |
| Raw Material Theme only | Insufficient for Figma-aligned custom components |

## Links

- `docs/DESIGN_SYSTEM.md`
- ADR-0004 (Asset Ownership)
