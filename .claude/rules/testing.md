# Testing Rules

Detail: [`docs/TESTING_GUIDE.md`](../../docs/TESTING_GUIDE.md).
Shared utilities: [`packages/testing/`](../../packages/testing/).
Tooling: `flutter_test`, `bloc_test` ^10, `mocktail` ^1.

## Mandatory

- Every bloc/cubit has `bloc_test` coverage of its event → state transitions,
  including failure paths.
- DTOs/mappers have `fromJson`/`toJson` round-trip unit tests, including alias
  keys and missing/partial fields (see
  [`apps/sanad_provider/test/features/registration/src/data/models/extraction_response_test.dart`](../../apps/sanad_provider/test/features/registration/src/data/models/extraction_response_test.dart)).
- Tests mirror the source path under the package/app `test/` directory.
- Mock collaborators with `mocktail` (`Mock`, `when`, `verify`). For widget
  tests, prefer a mocked bloc (`MockBloc`/`whenListen`) over a real one when
  the test only needs to render a given state — it's faster and avoids
  driving the bloc's real async/timer behavior. Use a real bloc in a widget
  test only when the test explicitly needs its actual event→state behavior,
  and avoid unnecessary real timers/streams (e.g. polling, debounce, repeating
  animations) in that setup.
- New behavior ships with a regression test in the same change.

## Do Not

- Do not use `pumpAndSettle()` while a repeating animation is on screen (e.g. the
  OTP caret) — use bounded `pump()` calls.
- Do not add `mockito` — `mocktail` is the project standard.
- Do not leave a fixed bug without a test that would have caught it.

## Preferred

- Prefer the helpers/fakes in `packages/testing` over re-rolling per test.
- Prefer table-driven tests for alias/edge-case matrices.

## Validation

- `melos run test` — `flutter test --coverage` across packages with a `test/` dir.
- `melos run coverage` — LCOV report.
