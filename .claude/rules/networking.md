# Networking Rules

Package: [`packages/network/`](../../packages/network/) (Dio).
Detail: [`docs/API_GUIDE.md`](../../docs/API_GUIDE.md),
[`docs/ARCHITECTURE_BLUEPRINT.md`](../../docs/ARCHITECTURE_BLUEPRINT.md).

## Mandatory

- All HTTP goes through the `network` package's client
  (`ApiClientImpl`/`SecureDioClient`), wired by `NetworkDI.init(...)` in each
  app's `configureDependencies()`.
- Data sources call the client; repositories map DTO → entity and return
  `TaskEither<Failure, T>`; the presentation layer never sees Dio types.
- Timeouts, base URLs, and interceptors come from `NetworkConfig`
  ([`packages/network/lib/src/network_config.dart`](../../packages/network/lib/src/network_config.dart))
  built per environment in `AppConfig.network`. Base defaults: 15s connect / 15s receive.
- DTOs live in `data/models/` with an explicit `fromJson`/`toJson`; endpoint
  paths live in `data/endpoints/`.
- Map Dio errors to the `Failure` hierarchy via the shared `error_mapper` /
  `failure_mapper`. A `Failure.message` may be an i18n key (e.g. `errors.timeout`)
  **or** raw backend prose — resolve it for display with
  `failure.localizedMessage()` (from `localization`), never `.tr()` blindly and
  never the raw `.message`.
- Consume the backend's own signals where present (e.g. a `missingFields` array
  on an extraction response) rather than inferring completeness client-side.

## Do Not

- Do not import `package:dio/` outside `network`, `sanad_client`, `sanad_provider`
  (enforced by `dep_rules.yaml` → `dio_allowed_packages`).
- Do not construct a second Dio instance or a parallel HTTP client.
- Do not auto-retry non-idempotent verbs (`POST`/`PATCH`) on timeout — the
  `retry_on_timeout_interceptor` deliberately excludes them to avoid duplicate
  mutations.
- Do not log tokens, Authorization headers, or full request/response bodies
  containing secrets (see [security.md](security.md)).

## Preferred

- Prefer adding a new interceptor to `network` over per-call ad-hoc logic.
- Prefer the shared pagination adapter (`page_parser`, `shared_ui` pagination)
  over bespoke paging.

## Validation

- `melos run analyze`; DTO round-trip unit tests (see `extraction_response_test.dart`).
