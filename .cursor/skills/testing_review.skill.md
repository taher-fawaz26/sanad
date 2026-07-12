# Testing Review Skill

Triggered when the user says: "review my tests", "add tests for X", "write a test for this use case", or "test coverage for this feature".

## Workflow

1. **Identify the layer** under test (UseCase, Repository, DataSource, BLoC, Widget, Golden)
2. **Read** `docs/TESTING_GUIDE.md` and existing tests in the same package
3. **Choose mock vs fake** using the decision tree in the guide
4. **Generate** the correct test file at the mirrored path
5. **Import** `package:testing/testing.dart` for shared helpers

## Per-Layer Checklist

### UseCase
- [ ] Mock the abstract `Repository` interface
- [ ] Test success and each failure path
- [ ] Use `TaskEitherX.expectRight()` / `expectLeft()`
- [ ] 100% coverage required

### Repository
- [ ] Mock remote/local datasources
- [ ] Verify `toEntity()` mapping
- [ ] Test `TaskEither` chain composition

### DataSource
- [ ] Use `FakeBaseApiClient` from `packages/testing`
- [ ] Test `fromJson` parsing edge cases

### BLoC
- [ ] Use `sandBlocTest` with mocked UseCases
- [ ] Register `registerFallbackValue` for param classes
- [ ] Assert full state sequence, not final state only

### Widget
- [ ] Use `pumpDsWidget` or `pumpDsWidgetDark`
- [ ] Inject fakes via `BlocProvider`
- [ ] No real network calls

### Golden (design_system only)
- [ ] Light and dark variants
- [ ] Store in `test/goldens/`
- [ ] Document `--update-goldens` if snapshots change

## Output Format

When generating tests:
1. State which test category applies
2. Explain mock vs fake choice
3. Provide complete, runnable test file
4. List any missing `registerFallbackValue` calls

## Never

- Mock concrete classes
- Use `setState` in widget tests
- Duplicate helpers that exist in `packages/testing`
- Guess translation keys — read `en-US.json` / `ar-AR.json`
