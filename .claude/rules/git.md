# Git / PR Rules

Detail: [`docs/CONTRIBUTING.md`](../../docs/CONTRIBUTING.md), [`docs/RELEASE.md`](../../docs/RELEASE.md).

## Mandatory

- Conventional Commits: `type(scope): summary`, where `scope` is the package or
  app name. Types in use: `feat`, `fix`, `chore`, `refactor`, `test`, `docs`.
- Branch naming: `feat/<scope>-<desc>`, `fix/<scope>-<desc>`, `chore/<scope>-<desc>`.
- Do not commit or push unless asked; never commit straight to `main` — branch first.
- Run the quality gate before opening a PR: `melos run check`
  (format → analyze → test → validate:arch → validate:l10n).
- Keep changes scoped to one feature/package; do not mix unrelated refactors
  into a fix.

## Do Not

- Do not commit generated files' conflicts, formatting noise, or secrets /
  `dart_defines/*.json` with real values.
- Do not bypass failing `validate:*` checks.
- Do not force-push shared branches.

## Preferred

- Prefer small, reviewable PRs with a test accompanying each fix.
- Reference the Jira key (`SAN-###`) in the PR description when applicable.

## Validation

- `melos run check` locally; CI runs `melos run ci` (bootstrap + check).
