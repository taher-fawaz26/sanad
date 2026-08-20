# Flutter / Dart Rules

Source of truth: [`analysis_options.yaml`](../../analysis_options.yaml)
(root config, inherited by every package via `include`).

## Mandatory

- Use `fvm flutter` / `fvm dart` for all commands. Flutter is pinned to
  **3.41.9** in [`.fvmrc`](../../.fvmrc); the global SDK is too old.
- Lint base is `very_good_analysis` with `strict-casts`, `strict-inference`,
  and `strict-raw-types` enabled. Analysis must pass with `--fatal-infos`.
- Use `package:` imports for cross-package and cross-`src/` references
  (`always_use_package_imports`). Single quotes only (`prefer_single_quotes`).
- Keep directives ordered (`directives_ordering`).
- Cancel `StreamSubscription`s and close sinks/controllers in `dispose`
  (`cancel_subscriptions`, `close_sinks`).
- Entities and bloc/cubit states extend `Equatable` (with a `copyWith` where
  mutation-by-copy is needed). DTOs are plain data classes with explicit
  `fromJson`/`toJson` — they do **not** need to extend `Equatable` unless a
  specific DTO is already designed that way. Don't add `Equatable` to an
  existing DTO as an unrelated cleanup.
- Generated files (`*.g.dart`, `*.freezed.dart`, `*.gen.dart`) are build output —
  never edit by hand; regenerate with `melos run generate`.

## Do Not

- Do not use `dynamic` calls (`avoid_dynamic_calls`) or positional boolean
  parameters (`avoid_positional_boolean_parameters`).
- Do not return `null` for a `Future` (`avoid_returning_null_for_future`).
- Do not hand-edit generated code or check in unformatted code.
- Do not add dependencies to the root `pubspec.yaml` — add them to the
  individual package/app pubspec that needs them.

## Preferred

- Prefer `switch` expressions and pattern matching (used widely, e.g.
  `AppConfig.network`, sealed-type dispatch).
- Prefer `const` constructors and literals wherever the analyzer allows.
- Prefer small, composable widgets over large `build` methods.

## Validation

- `melos run format` (check) / `melos run format:fix` (apply).
- `melos run analyze`.
