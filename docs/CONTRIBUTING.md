# Contributing

## Getting Started

```bash
git clone https://github.com/trypass-ai/sanad.git
cd sanad
melos bootstrap
```

## Conventional Commits

```
feat(scope): add branch management page
fix(network): handle token refresh race condition
chore(design_system): add AppWizardStepIndicator
refactor(auth): extract login validation
test(otp): add resend timer tests
docs(routing): document auth guard pattern
```

Scope = package or app name.

## Branch Naming

- `feat/<scope>-<description>` — new features
- `fix/<scope>-<description>` — bug fixes
- `chore/<scope>-<description>` — maintenance

## Development Workflow

1. Create branch from `main`
2. Make changes following Cursor rules in `.cursor/rules/`
3. Batch edits, then analyze affected package once
4. Run tests for affected package
5. Update relevant `docs/*.md`
6. Create PR with conventional commit title

## Melos Scripts

| Command | Purpose |
|---------|---------|
| `melos bootstrap` | Install/link all packages |
| `melos analyze` | Full workspace analyze (CI only) |
| `melos test` | Run all tests |
| `melos format` | Check formatting |
| `melos format:fix` | Apply formatting |
| `melos check` | format + analyze + test |
| `melos ci` | bootstrap + check (CI entry) |

## PR Checklist

- [ ] Conventional commit message
- [ ] One logical change per PR
- [ ] Analyzer clean on affected package(s)
- [ ] Tests pass for affected package(s)
- [ ] Localization keys in both JSON files (if UI changes)
- [ ] DS tokens used (no raw colors/spacing/typography)
- [ ] Relevant docs updated
- [ ] No generated files committed

## CI Pipeline

GitHub Actions (`.github/workflows/`):
1. `analyze.yml` — `melos analyze`
2. `test.yml` — `melos test`
3. `coverage.yml` — coverage report
4. `release.yml` — build and deploy

Run locally: `melos ci`

## Code Review

Use skills in `.cursor/skills/` for structured reviews:
- `review.skill.md` — general code review
- `feature_review.skill.md` — feature package review
- `design_review.skill.md` — DS compliance
- `security_review.skill.md` — security audit
