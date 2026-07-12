---
name: release_review
description: Release readiness review — analyzer, tests, CI, builds, version, changelog
---

# Release Review Skill

Perform a complete release readiness review.

## 1. Analyzer Status

```bash
melos analyze
```
- [ ] Zero errors
- [ ] Zero warnings

## 2. Test Coverage

```bash
melos test
melos coverage
```
- [ ] All tests pass
- [ ] Domain/data layers ≥ 80% coverage

## 3. CI Status

Verify GitHub Actions:
- [ ] `analyze.yml` — pass
- [ ] `test.yml` — pass
- [ ] `coverage.yml` — pass

## 4. Build Verification

```bash
melos build:provider:android -- --dart-define=ENV=prod
melos build:client:android -- --dart-define=ENV=prod
```
- [ ] Provider APK builds successfully
- [ ] Client APK builds successfully

## 5. Version Verification

- [ ] `apps/sanad_client/pubspec.yaml` version bumped
- [ ] `apps/sanad_provider/pubspec.yaml` version bumped
- [ ] Version matches CHANGELOG entry

## 6. Changelog Review

- [ ] CHANGELOG.md entries match conventional commits since last release
- [ ] Breaking changes documented
- [ ] Migration notes included if needed

## 7. Documentation Review

- [ ] All `docs/*.md` updated for features in this release
- [ ] No stale code examples
- [ ] `PACKAGE_GUIDE.md` reflects current package list

## 8. Release Checklist

- [ ] Sign APK/IPA
- [ ] Update store metadata
- [ ] Git tag created and pushed
- [ ] Team notified

## Output

Go/No-Go decision with blocking issues listed.
