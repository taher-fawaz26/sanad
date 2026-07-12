# Melos Workspace

## Overview

Sanad uses [Melos](https://melos.invertase.dev/) for monorepo management. Configuration in `melos.yaml` at root.

## Workspace Structure

```yaml
# melos.yaml
name: sanad
packages:
  - apps/*
  - packages/*
```

Root `pubspec.yaml` lists workspace members. All packages use `publish_to: none`.

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

1. `mkdir packages/<name>/lib/src`
2. Create `pubspec.yaml` with `publish_to: none`
3. Add to root `pubspec.yaml` workspace list
4. Add to `melos.yaml` packages list
5. Create `analysis_options.yaml`, barrel file, `test/` folder
6. `melos bootstrap`

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
