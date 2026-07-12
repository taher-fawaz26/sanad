---
name: package_creation
description: Create a new reusable package — scaffold, workspace registration, DI, tests, docs
---

# Package Creation Skill

Create a new package in the Sanad monorepo.

## Step 1 — Scaffold

```bash
mkdir -p packages/<name>/lib/src
mkdir -p packages/<name>/test
```

Create `pubspec.yaml`:
```yaml
name: <name>
description: <description>
publish_to: none
version: 0.0.1

environment:
  sdk: '>=3.11.0 <4.0.0'

dependencies:
  core:
    path: ../core

dev_dependencies:
  flutter_test:
    sdk: flutter
  very_good_analysis: ^6.0.0
```

## Step 2 — Workspace Registration

1. Add to root `pubspec.yaml` workspace list
2. Add to `melos.yaml` packages list

## Step 3 — Analysis Options

```yaml
include: package:very_good_analysis/analysis_options.yaml
```

## Step 4 — Barrel File

```dart
// lib/<name>.dart
library;
export 'src/...';
```

## Step 5 — Clean Arch Folders (Feature Packages)

```
lib/src/
  data/
  domain/
  presentation/
  di/<name>_di.dart
  routes/<name>_routes.dart
```

## Step 6 — DI Module

```dart
abstract final class NameDI {
  static void init() {
    // Register lazy singletons and factories
  }
}
```

## Step 7 — Tests

Create `test/` with at least one smoke test.

## Step 8 — Melos Bootstrap

```bash
melos bootstrap
```

## Step 9 — Documentation

Add entry to `docs/PACKAGE_GUIDE.md`.

## Step 10 — Architecture Checklist

- [ ] No circular dependencies
- [ ] Correct dependency direction
- [ ] Barrel exports only public API
- [ ] `publish_to: none`
- [ ] Analyzer clean
