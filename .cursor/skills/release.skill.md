---
name: release
description: Release workflow — version bump, build commands, changelog, git tag
---

# Release Skill

Prepare and execute a release for Sanad apps.

## Pre-Release Checklist

- [ ] `melos analyze` — zero errors
- [ ] `melos test` — all tests pass
- [ ] Coverage meets 80% for domain/data layers
- [ ] `docs/*.md` updated for new features
- [ ] CHANGELOG updated with conventional commits since last release
- [ ] Version bumped in app `pubspec.yaml`

## Build Commands

```bash
# Android
melos build:provider:android -- --dart-define=ENV=prod
melos build:client:android -- --dart-define=ENV=prod

# iOS
melos build:provider:ios -- --dart-define=ENV=prod
melos build:client:ios -- --dart-define=ENV=prod
```

## Version Bump

Update `version:` in `apps/sanad_client/pubspec.yaml` and `apps/sanad_provider/pubspec.yaml`.

## Git Tag

```bash
git tag -a v1.2.0 -m "Release v1.2.0"
git push origin v1.2.0
```

## CI Pipeline

GitHub Actions: `analyze.yml` → `test.yml` → `coverage.yml` → `release.yml`

Run full CI locally: `melos ci`

## Post-Release

- Update store metadata (Google Play / App Store)
- Notify team of release notes
- Monitor crash reports (Firebase Crashlytics when enabled)
