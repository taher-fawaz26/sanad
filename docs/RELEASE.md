# Release

## Release Workflow

```
feat branch → PR → review → merge to main → version bump → tag → build → deploy
```

## Versioning Strategy

- App version in `apps/*/pubspec.yaml` `version:` field
- Internal packages: `publish_to: none` — no semver required
- Changes tracked via conventional commits
- CHANGELOG.md updated per release

## Hybrid Pipeline (GitHub Actions + Fastlane)

| Step | Tool | Purpose |
|------|------|---------|
| Quality gate | GitHub Actions | analyze + test |
| Build APK/IPA | Flutter | `melos build:*` |
| Release notes | `tools/generate_release_notes.dart` | CHANGELOG → GitHub Release |
| Android upload | Fastlane `supply` | Play Store internal track |
| iOS signing | Fastlane `match` | Certificate management |
| iOS upload | Fastlane `deliver` | App Store Connect |

Fastlane lanes live in `fastlane/Fastfile`. Required secrets:

- `PLAY_STORE_JSON_KEY` — Google Play service account JSON
- `MATCH_GIT_URL` / `MATCH_PASSWORD` — iOS certificate repo
- `FASTLANE_USER` — Apple ID for deliver

## Environment Mapping

| Env | Branch | `ENV` dart-define | Store track |
|-----|--------|-------------------|-------------|
| Dev | `feat/*` | `dev` | — |
| QA | `release/*` | `qa` | Internal |
| Stage | `release/*` manual | `stage` | Alpha |
| Production | `v*.*.*` tag | `prod` | Production |

## Pre-Release Checklist

- [ ] `melos analyze` — zero errors
- [ ] `melos test` — all tests pass
- [ ] Coverage ≥ 80% for domain/data layers
- [ ] `docs/*.md` updated for new features
- [ ] CHANGELOG.md updated
- [ ] Version bumped in both app `pubspec.yaml` files
- [ ] Localization keys complete (both JSONs)

## Build Commands

### Android

```bash
melos build:provider:android -- --dart-define=ENV=prod
melos build:client:android -- --dart-define=ENV=prod
```

### iOS

```bash
melos build:provider:ios -- --dart-define=ENV=prod
melos build:client:ios -- --dart-define=ENV=prod
```

## CI/CD Pipeline

GitHub Actions (`.github/workflows/`):

| Workflow | Trigger | Steps |
|----------|---------|-------|
| `analyze.yml` | PR + push | `melos analyze` |
| `test.yml` | PR + push | `melos test` |
| `coverage.yml` | PR + push | `melos coverage` |
| `release.yml` | Tag push | Build + deploy |

Run full CI locally: `melos ci`

## Git Tag

```bash
git tag -a v1.2.0 -m "Release v1.2.0"
git push origin v1.2.0
```

## Changelog Format

```markdown
## [1.2.0] - 2026-07-12

### Added
- feat(branches): add branch management screen
- feat(design_system): AppWizardStepIndicator component

### Fixed
- fix(network): token refresh race condition

### Changed
- refactor(auth): extract login validation to use case
```

## Store Deployment

### Android (Google Play)

1. Build release APK/AAB with `ENV=prod`
2. Sign with release keystore
3. Upload to Google Play Console
4. Update store listing if needed

### iOS (App Store)

1. Build release IPA with `ENV=prod`
2. Archive in Xcode
3. Upload via App Store Connect
4. Submit for review

## Post-Release

- Monitor crash reports (Firebase Crashlytics when enabled)
- Notify team of release notes
- Create next development branch if needed

## Release Review

Use `release_review.skill.md` for structured release readiness audits.
