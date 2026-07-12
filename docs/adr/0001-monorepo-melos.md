# ADR-0001: Monorepo with Melos

**Date:** 2025-06-01  
**Status:** Accepted  
**Deciders:** Platform Architecture Team

## Context

Sanad ships two Flutter apps (client and provider) sharing authentication, networking, design system, and most business logic. Duplicating packages across repos would cause version drift and double maintenance.

## Decision

Use a single Git monorepo managed by [Melos](https://melos.invertase.dev/) with:
- `apps/` for thin app shells
- `packages/` for all shared and feature code
- Root workspace `pubspec.yaml` listing all members
- `melos bootstrap` to link local path dependencies

## Consequences

### Positive
- Atomic cross-package changes in one PR
- Shared CI, linting, and documentation
- Local path deps eliminate publish/version overhead

### Negative
- Larger clone size
- Requires Melos familiarity for new developers

### Risks
- Workspace misconfiguration breaks all packages — mitigated by `melos doctor`

## Alternatives Considered

| Option | Reason rejected |
|--------|----------------|
| Multi-repo with published packages | Version coordination overhead; slow iteration |
| Single app with flavors only | Client/provider diverge too much in navigation and features |

## Links

- `docs/MELOS.md`
- `pubspec.yaml` (`melos:` key — Melos 7.x removed the standalone `melos.yaml` file; see `docs/MELOS.md` for the migration note)
