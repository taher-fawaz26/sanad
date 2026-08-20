# State Management Rules

Solution: **flutter_bloc** (BLoC + Cubit). Decision: [`docs/adr/0006-bloc-state-management.md`](../../docs/adr/0006-bloc-state-management.md).
Result/error type: **fpdart `TaskEither`** — [`docs/adr/0005-taskeither-result-pattern.md`](../../docs/adr/0005-taskeither-result-pattern.md).

## Mandatory

- All non-trivial screen/feature state lives in a `Bloc` or `Cubit`, not in the widget.
- Events and states are declared as `part` files next to the bloc
  (`xxx_bloc.dart` + `part 'xxx_event.dart'` + `part 'xxx_state.dart'`).
- States extend `Equatable`; list every field in `props`; mutate via `copyWith`.
- Represent async lifecycle with the shared `RequestStatus` enum
  (`initial`/`loading`/`success`/`failure`) rather than ad-hoc booleans.
- Use cases return `TaskEither<Failure, T>`; blocs `.run()` them and `fold` the
  result into a success/failure state emission.
- Guard submit/mutation events against double-taps with the `droppable()`
  transformer (see `organization_settings_bloc.dart`).
- Surface mutation progress/results through `MutationListener` and read/write UI
  loading via the shared loading architecture (`AppSkeletonizer` for reads,
  `AppProgress`/`MutationListener` for mutations).

## Do Not

- Do not introduce another state-management library (Riverpod, Provider,
  GetX, MobX). BLoC is the single sanctioned solution.
- Do not put business logic, API calls, or navigation decisions inside widgets.
- Do not throw exceptions across the use-case boundary — return a `Failure`.
- Do not display `Failure.message` raw. Convert with
  `failure.localizedMessage()` from `localization` (it distinguishes an i18n
  key from raw backend prose). See [networking.md](networking.md).
- Do not clear user-entered form state on a failed mutation — preserve the
  attempted input so the user can retry.

## Preferred

- Prefer `BlocBuilder`/`BlocSelector` scoped to the smallest rebuild surface.
- Prefer one bloc per feature responsibility; compose multiple blocs on a page
  rather than one god-bloc.

## Validation

- `bloc_test` + `mocktail` unit tests for every bloc (see [testing.md](testing.md)).
