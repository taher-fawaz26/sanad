# CLAUDE.md — Sanad Monorepo

Entry point for Claude Code sessions. Read this first, then load only the rule
and feature docs relevant to your task. **Do not scan the whole repository for
ordinary feature work.**

## Project Identity

**Sanad** is a Flutter monorepo powering two mobile apps that share
infrastructure packages:

| App | Path | Audience |
|-----|------|----------|
| Sanad Client | `apps/sanad_client` | End-users booking services |
| Sanad Provider | `apps/sanad_provider` | Service providers |
| Design Catalog | `apps/design_catalog` | Component preview/dev app |

**Stack:** Flutter (pinned **3.41.9** via `fvm`, Dart SDK ≥ 3.11), Melos 7
workspace, BLoC (flutter_bloc), go_router, get_it, Dio, fpdart (`TaskEither`),
easy_localization, Hive CE + flutter_secure_storage, Firebase (`packages/analytics`
observability + Messaging; see `packages/analytics/lib/src/firebase_observability_service.dart`).

**Structure:** shared packages under `packages/`; provider-only shared packages
under `apps/sanad_provider/packages/` (`branches`, `services`, `workers`,
`provider_rbac`); app-specific features under `apps/<app>/lib/src/features/`.
Package dependencies are tiered and machine-enforced by
[`dep_rules.yaml`](dep_rules.yaml).

> Use `fvm flutter` / `fvm dart`, never the global SDK.

> **⚠️ Stale-path warning:** several older guides under `docs/` (including
> `docs/ARCHITECTURE.md`, `docs/FEATURE_GUIDE.md`, `docs/PACKAGE_GUIDE.md`,
> `docs/MELOS.md`, `docs/TESTING_GUIDE.md`, `docs/API_GUIDE.md`) describe
> feature packages living at `packages/features/<name>/`. **That directory does
> not exist in this repository and must not be used.** The actual, current
> layout is:
> - shared packages: `packages/<name>/` (e.g. `packages/auth/`, `packages/otp/`)
> - provider-local shared packages: `apps/<app>/packages/<name>/` (e.g.
>   `apps/sanad_provider/packages/branches/`)
> - app-local features: `apps/<app>/lib/src/features/<name>/`
>
> For any package/path decision, in this priority order:
> 1. the actual repository tree
> 2. the `workspace:` list in [`pubspec.yaml`](pubspec.yaml)
> 3. [`dep_rules.yaml`](dep_rules.yaml)
>
> Do not treat a doc that uses `packages/features/` as canonical for current
> paths — its structural claims are stale even where its concepts/rationale
> still hold.

### Documentation verification guard

When an existing guide under `docs/` makes a claim about **file paths,
package names, package locations, or library/barrel conventions**, verify it
against the actual tree (`ls`/`find`), `pubspec.yaml`, and/or `dep_rules.yaml`
before acting on it. Stale documentation must never override current,
machine-enforced repository structure. (Non-structural claims — rationale,
patterns, business rules — don't need this check.)

## Mandatory Development Rules

Read the relevant rule file before writing code. All are in
[`.claude/rules/`](.claude/rules/):

| Rule | When to read |
|------|--------------|
| [architecture.md](.claude/rules/architecture.md) | Adding packages/features, imports, layering |
| [flutter.md](.claude/rules/flutter.md) | Any Dart/Flutter code, lints, tooling |
| [state-management.md](.claude/rules/state-management.md) | Blocs, state, use cases, results |
| [routing.md](.claude/rules/routing.md) | Navigation, routes, RBAC gating |
| [networking.md](.claude/rules/networking.md) | API calls, DTOs, error mapping |
| [security.md](.claude/rules/security.md) | Tokens, storage, secrets, logging |
| [testing.md](.claude/rules/testing.md) | Any change (tests ship with it) |
| [ui.md](.claude/rules/ui.md) | Widgets, design system, tokens |
| [localization.md](.claude/rules/localization.md) | User-facing strings, RTL |
| [git.md](.claude/rules/git.md) | Commits, branches, PRs |

## Documentation Navigation

Start at [`docs/index.md`](docs/index.md). It routes to:

- **Architecture / patterns** → [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md),
  [`docs/ARCHITECTURE_BLUEPRINT.md`](docs/ARCHITECTURE_BLUEPRINT.md),
  [`docs/FEATURE_GUIDE.md`](docs/FEATURE_GUIDE.md),
  [`docs/PACKAGE_GUIDE.md`](docs/PACKAGE_GUIDE.md), [`docs/MELOS.md`](docs/MELOS.md)
- **Features** → [`docs/features/`](docs/features/) (per-feature flow docs + index)
- **API** → [`docs/API_GUIDE.md`](docs/API_GUIDE.md)
- **Security** → [`docs/SECURITY.md`](docs/SECURITY.md)
- **Decisions (ADRs)** → [`docs/adr/`](docs/adr/)
- **Routing / DI / Config** → [`docs/ROUTING.md`](docs/ROUTING.md),
  [`docs/adr/0008-get-it-di.md`](docs/adr/0008-get-it-di.md),
  [`docs/CONFIGURATION.md`](docs/CONFIGURATION.md), [`docs/FLAVORS.md`](docs/FLAVORS.md)

> Note: the root [`ARCHITECTURE.md`](ARCHITECTURE.md) is a v3.0 (2026-07-10)
> narrative that is **partially stale** (its package/feature tables predate later
> renames and deletions). Treat [`dep_rules.yaml`](dep_rules.yaml) and the actual
> `workspace:` list in [`pubspec.yaml`](pubspec.yaml) as the source of truth.

## Task Workflow

1. **Identify** the affected app/package/feature (use `docs/index.md` and
   `docs/features/`, not a repo-wide scan).
2. **Read** the relevant rule file(s) above.
3. **Read** the relevant feature doc under `docs/features/`.
4. **Inspect** only the implementation files the task touches.
5. **Make the smallest correct change** — no speculative refactors.
6. **Add/update tests** in the same change ([testing.md](.claude/rules/testing.md)).
7. **Update docs** when behavior or architecture changes.
8. **Validate**: `fvm dart analyze` the touched files, then the relevant
   `melos run` gate (`analyze` / `test` / `validate:arch` / `validate:l10n`).

## Token Efficiency

- Do **not** dump or scan the entire repository for ordinary feature work.
- Begin from `docs/index.md` → one or two rule files → one feature doc → the
  specific source files named there.
- Widen the search only when evidence in those files requires it.
- Prefer targeted `grep`/`glob` over broad directory reads.

## Common Commands

```bash
melos bootstrap            # after clone / adding a package
melos run analyze          # dart analyze --fatal-infos (all packages)
melos run test             # flutter test --coverage
melos run check            # format + analyze + test + validate:arch + validate:l10n
melos run validate:arch    # dependency graph + import-layer rules
melos run validate:l10n    # locale key parity
melos run feature:create -- <name> shared|provider|client
```

## Hard Constraints

- Never commit/push unless asked; branch off `main` first ([git.md](.claude/rules/git.md)).
- Never add dependencies to the root `pubspec.yaml`.
- Never import `package:dio/` outside `network`/`sanad_client`/`sanad_provider`.
- Never log tokens/secrets or hardcode user-facing strings.
