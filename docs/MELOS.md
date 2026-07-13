# Melos Workspace

## Overview

Sanad uses [Melos](https://melos.invertase.dev/) v7.x for monorepo management. Melos 7.x introduced native Dart pub workspaces — there is **no standalone `melos.yaml` file**. All Melos configuration (scripts, ide settings, command hooks) lives under a `melos:` key inside the root `pubspec.yaml`.

See the [7.x migration guide](https://melos.invertase.dev/guides/migrations#6xx-to-7xx) for background.

## Workspace Structure

```yaml
# pubspec.yaml (workspace root)
name: sanad
publish_to: none
environment:
  sdk: ">=3.11.0 <4.0.0"

workspace:
  - apps/sanad_client
  - apps/sanad_provider
  - packages/features/auth
  # ...infrastructure under packages/, features under packages/features/

dev_dependencies:
  melos: ^7.0.0

melos:
  # scripts, ide, command config — see pubspec.yaml
```

The `workspace:` list (native Dart pub workspaces) is the single source of truth for member packages — package discovery no longer uses a `melos.packages` glob. Each member package's `pubspec.yaml` must declare `resolution: workspace`. All packages use `publish_to: none`.

## Running Scripts

Scripts are invoked with `melos run <script>`. When passing arguments, always
use the `--` separator so Melos forwards them to the script instead of trying
to parse them as its own CLI flags:

```bash
melos run feature:create -- orders shared
melos run package:create -- analytics infrastructure
```

Passing `--flags` directly after a bare `melos <script>` command (e.g. `melos feature:create orders --shared`) does **not** work — Melos intercepts unrecognized flags itself.

## Bootstrap

```bash
melos bootstrap
```

Run after any `pubspec.yaml` change. Links local packages and runs `pub get`.
**Never** run `flutter pub get` directly in workspace packages.

## Scripts

| Script | Command | Purpose |
|--------|---------|---------|
| bootstrap | `melos bootstrap` | Link packages, pub get |
| analyze | `melos analyze` | Full workspace analyze (CI only) |
| test | `melos test` | Run tests where `test/` exists |
| test:dart | `melos test:dart` | Pure-Dart package tests |
| format | `melos format` | Check formatting |
| format:fix | `melos format:fix` | Apply formatting |
| generate | `melos generate` | build_runner across packages |
| generate:watch | `melos generate:watch` | build_runner watch mode |
| clean | `melos clean` | flutter clean all packages |
| coverage | `melos coverage` | Tests + LCOV report |
| check | `melos check` | format + analyze + test |
| ci | `melos ci` | bootstrap + check |
| build:client:android | `melos build:client:android` | Client release APK |
| build:client:ios | `melos build:client:ios` | Client release IPA |
| build:provider:android | `melos build:provider:android` | Provider release APK |
| build:provider:ios | `melos build:provider:ios` | Provider release IPA |

## Creating a Package

1. **Infrastructure:** Create `packages/<name>/` with `pubspec.yaml` (`publish_to: none`)
2. **Feature:** Use `melos run feature:create -- <name> shared` (creates `packages/features/<name>/`)
3. Add to root `pubspec.yaml` workspace list (`packages/<name>` or `packages/features/<name>`)
4. Create `analysis_options.yaml`, barrel file, `test/` folder
5. `melos bootstrap`

Or scaffold automatically: `melos run package:create -- <name> <type>` (see `package_creation.skill.md`).

See `package_creation.skill.md` for details.

## Adding a Dependency

1. Add to package `pubspec.yaml`:
   ```yaml
   dependencies:
     network:
       path: ../network
   ```
2. `melos bootstrap`

## melos exec

Run a command in specific packages:

```bash
melos exec --scope=auth -- flutter test
melos exec --scope=design_system -- dart analyze
```

## When NOT to Run Workspace-Wide Commands

| Command | When | Alternative |
|---------|------|-------------|
| `melos analyze` | CI / release only | `cd packages/<name> && flutter analyze` |
| `melos check` | Pre-commit only | Per-package analyze + test |
| `melos test` | CI / release only | Per-package `flutter test` |

## CI Integration

```bash
melos ci  # bootstrap → format → analyze → test
```

Used in `.github/workflows/analyze.yml` and `test.yml`.

## Conventions

- Package naming: `snake_case`, describes domain
- All packages: `publish_to: none`
- Local refs: `path: ../<package>`
- Versioning: track via conventional commits, not semver
