# Security Rules

Detail: [`docs/SECURITY.md`](../../docs/SECURITY.md).
Storage: [`packages/storage/`](../../packages/storage/); tokens: [`packages/network/lib/src/token/`](../../packages/network/lib/src/token/).

## Mandatory

- Store access/refresh tokens only via `TokenStorage`/`TokenStorageImpl`
  (backed by `flutter_secure_storage`). Never in Hive plaintext, shared prefs,
  or in-memory globals.
- Hive boxes that hold sensitive data use the encrypted store
  (`HiveEncryptionKeyManager` + `HiveLocalStorage`).
- Token attachment and 401 refresh are handled centrally by `auth_interceptor`
  in `network`. On refresh failure the app wipes the session
  (`SessionManager.clear()`) and redirects to Login.
- Environment/base URLs come from `AppConfig` via the `ENV` dart-define
  (`dev`/`qa`/`stage`/`prod`); production is `api.trysanad.us`.
- Secrets/config are injected at build time via
  `--dart-define-from-file=dart_defines/<platform>.json` — keep real values out
  of source. `dart_defines/ios.example.json` is the committed template.

## Do Not

- Do not log tokens, Authorization headers, OTPs, or full auth request/response
  bodies. The `logging_interceptor` must not leak credentials.
- Do not put secrets, API keys, or tokens in source, in the repo, in URLs/query
  strings, or in analytics/crash payloads.
- Do not weaken TLS or bypass certificate validation.
- Do not persist PII outside the sanctioned storage wrappers.

## Preferred

- Prefer failing closed: on an auth/permission ambiguity, deny and surface a
  clear error rather than proceeding.

## Observed / NEEDS_CONFIRMATION (not enforced rules — verify before relying)

- SSL pinning: `NEEDS_CONFIRMATION` — not established from the repo.
- WebView hardening (JS bridge, permissions) for the contact flow:
  `NEEDS_CONFIRMATION` — no dedicated WebView security config located.
- Jailbreak/root detection: `UNKNOWN`.

## Validation

- `melos run analyze`; `security-review` skill for pending-diff review.
