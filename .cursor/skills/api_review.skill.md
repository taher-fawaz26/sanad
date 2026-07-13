# API Review Skill

Triggered when the user says "review this data layer", "check my API", or "review repository".

## Checklist

- [ ] DataSource returns `TaskEither<Failure, T>`
- [ ] No `Dio` imports outside `network`
- [ ] Errors mapped via `FailureMapper`
- [ ] Response model has `fromJson` + `toEntity()`
- [ ] Request model has `toJson()`
- [ ] Repository composes with `map` / `flatMap` / `chainFirst`
- [ ] API paths in `<Feature>ApiPaths` class
- [ ] Pagination uses shared types from `network`

## Reference

`docs/API_GUIDE.md`, `packages/features/auth/lib/src/data/`
