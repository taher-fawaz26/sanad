# Architecture Rules

Source of truth: [`dep_rules.yaml`](../../dep_rules.yaml) (machine-enforced),
[`docs/ARCHITECTURE.md`](../../docs/ARCHITECTURE.md), [`docs/adr/`](../../docs/adr/).

## Mandatory

- Respect the tiered dependency graph in [`dep_rules.yaml`](../../dep_rules.yaml)
  (`layer_order`, tiers 0–7): a package in tier N may only depend on packages in
  tier ≤ N. Adding a package without a tier is a build error under `--strict`.
- Each feature follows Clean Architecture with three layers:
  `src/domain/`, `src/data/`, `src/presentation/`, plus `src/di/`, `src/module/`,
  `src/routes/`. [`docs/FEATURE_GUIDE.md`](../../docs/FEATURE_GUIDE.md) documents
  this internal layout; its top-level package **paths** are stale — see
  [`CLAUDE.md`](../../CLAUDE.md)'s stale-path warning.
- Dependency direction is inward only: `presentation → domain`, `data → domain`.
  Domain depends on nothing else in the feature.
- Expose a package's public surface **only** through its barrel file
  (`lib/<package>.dart`). Import other packages via `package:` URIs.
- New workspace packages must be added to the `workspace:` list in the root
  [`pubspec.yaml`](../../pubspec.yaml) AND given a tier in `dep_rules.yaml`.
- Register a feature's dependencies through a `FeatureModule` subclass
  (see [`packages/core/lib/src/module/feature_module.dart`](../../packages/core/lib/src/module/feature_module.dart)).

## Do Not

- Do not create upward dependencies. Packages must never import from `apps/`
  (app-local packages under `apps/*/packages/` are the only exception, and only
  for provider-only code other packages import).
- Do not import across layers backwards: `domain/` must not import `/data/`,
  `/presentation/`, `package:dio/`, or `package:flutter/`; `data/` must not
  import `/presentation/` (enforced by `layer_rules` in `dep_rules.yaml`).
- Do not export `*_impl.dart` or `internal/**` from a barrel (`disallow_barrel_export`).
- Do not import `package:dio/` outside `network`, `sanad_client`, `sanad_provider`.
- Do not import `infinite_scroll_pagination` outside `shared_ui`.
- Do not re-introduce packages `dep_rules.yaml` lists as deleted:
  `shared_widgets`, `dependencies`, `settings`, `api`, `shared_models`,
  `shared_blocs`, `domain`. (Separately, `shared_features` — an older
  aggregation layer wrapping `auth`/`otp`/`settings`/etc. — was also removed;
  it predates `dep_rules.yaml`'s tracked list. See `docs/ARCHITECTURE.md` §6
  for why. Don't recreate it either.)
- Do not reuse a shared model when two apps genuinely diverge (see the
  application-specific `profile` decision in `docs/ARCHITECTURE.md`).

## Preferred

- Prefer app-local features (`apps/<app>/lib/src/features/<name>/`) over new
  workspace packages unless another package must import the code.
- Prefer scaffolding via generators: `melos run feature:create -- <name> shared|provider|client`
  and `melos run package:create -- <name> <type>`.

## Validation

- `melos run validate:arch` — runs `validate:deps --strict` + `validate:imports`.
- `melos run analyze` — `dart analyze . --fatal-infos` across all packages.
