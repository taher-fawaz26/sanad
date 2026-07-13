---
name: migration
description: Move code between packages — update imports, barrel, pubspec, analyze
---

# Migration Skill

Safely move code from one package to another.

## Pre-Migration

1. Search workspace for all usages of the code being moved
2. Identify all import paths that will change
3. Check dependency direction — target package must be at same or lower layer

## Steps

1. **Move files** to target package's `lib/src/` directory
2. **Update barrel** — export from target package's `lib/<name>.dart`
3. **Remove exports** from source package barrel
4. **Update pubspec.yaml** — add dependency in consuming packages if needed
5. **Update all imports** across workspace:
   ```dart
   // Before
   import 'package:old_package/src/widgets/my_widget.dart';
   // After
   import 'package:new_package/new_package.dart';
   ```
6. Run `melos bootstrap`
7. Analyze affected packages only

## Post-Migration

- [ ] No broken imports
- [ ] No circular dependencies introduced
- [ ] Barrel files updated in both packages
- [ ] `docs/PACKAGE_GUIDE.md` updated
- [ ] `docs/DEPENDENCY_GRAPH.md` updated if deps changed

## Common Migrations

- Widget from app → `shared_widgets` or `design_system`
- Utility from app → `core` or `utilities`
- Feature logic from app → new feature package
