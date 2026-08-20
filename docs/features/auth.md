# Auth (Shared)

## Purpose

The application's single authentication and session vertical: passwordless
email OTP login/signup, session lifecycle, token-backed identity, and the
splash/suspended screens both apps route through.

## Location

[`packages/auth/`](../../packages/auth/) — shared package, tier 4 in
`dep_rules.yaml`. Barrel: `packages/auth/lib/auth.dart`.

## Architecture

Clean Architecture: `src/domain/` (entities, enums, repository contract, use
cases), `src/data/` (DTOs, endpoints, repository impl), `src/presentation/`
(bloc, pages, widgets, session helpers), `src/session/` (`SessionManager`,
`SessionCache`, `SessionRepository`), `src/di/` (`AuthDI`), `src/module/`
(`AuthModule`), `src/routes/` (`AuthRoutes`), `src/routing/` (`AuthShell`,
OTP route args), `src/auth/` (`AuthStatus`, `AuthStatusNotifier`).

Registered as a `FeatureModule`: `AuthModule` (`dependencies: []`,
`registerDependencies() => AuthDI.init(...)`), consumed by both apps' DI/router
composition roots.

## Main Flow

`SplashPage` → `SessionManager.restore()` rehydrates a persisted session from
Hive (runs in `AuthModule.initialize()`, after DI registration) → router
redirects to home or `AuthRoutes.login` based on `AuthStatusNotifier` →
`AuthPage` (email entry) → shared OTP route (composed per-app via
`AuthShell.otpRoute`, backed by the `otp` package — see
[otp.md](otp.md)) → on verify, `AuthBloc` starts the session → app-owned
post-verification navigation (dashboard vs onboarding) takes over.

`SuspendedPage` renders when the account status blocks sign-in.

## Main State Management

- `presentation/bloc/auth/auth_bloc.dart` — `AuthBloc` (events in
  `auth_event.dart`, state in `auth_state.dart`).
- `session/session_manager.dart` — `SessionManager`: owns the full
  `AuthSessionEntity` (tokens, user, profile, account settings, permissions,
  verification flags) and drives `AuthStatusNotifier` so routers redirect
  correctly. `current` composes live tokens from `TokenManager` on every read,
  so it reflects a silent refresh by the network layer's auth interceptor
  without callback plumbing. Every feature needing identity data should read
  from `SessionManager`, not duplicate its own cache.
- `auth/auth_status_notifier.dart` — `AuthStatusNotifier`, the redirect signal
  both app routers listen to.

## Important APIs

`data/endpoints/auth_api_paths.dart`:
`auth/signup`, `auth/signup/verify`, `auth/login`, `auth/login/verify`,
`auth/social/signup`, `auth/social/login`, `auth/resend-otp`,
`auth/resend-info`, `auth/logout`, `me`.

Use cases (domain): `RequestLoginOtpUseCase`, `VerifyLoginOtpUseCase`,
`RequestSignupOtpUseCase`, `VerifySignupOtpUseCase`, `SocialLoginUseCase`,
`SocialSignupUseCase`, `ResendOtpUseCase`, `GetResendInfoUseCase`,
`CheckSigninStatusUseCase`, `GetCurrentUserUseCase`, `LogoutUseCase`,
`DeleteAccountUseCase`.

## Important Integrations

- `network` — `TokenManager`, `AuthInterceptor` (attach/refresh), routed
  through `SessionManager`.
- `storage` — Hive-backed session persistence (`SessionCache`).
- `otp` — the OTP entry/verify UI this feature drives via `AuthShell.otpRoute`.
- Each app's router aggregates `AuthModule.routes(...)` alongside other
  features' routes via `moduleRegistry.allRoutes(...)`.

## Business Rules

- On 401-refresh failure, the app performs a full session wipe
  (`SessionManager.clear()`, tokens + Hive snapshot + in-memory cache) and the
  router redirects to Login (see [security.md](../../.claude/rules/security.md)).
- `onSessionBoundary` (typically `moduleRegistry.disposeAll()`) is invoked at
  session start/end so feature modules can reset their own state.

## Important Constraints

- `SessionManager` is the single source of truth for identity — reading tokens
  or user data any other way risks staleness after a silent refresh.

## Known Edge Cases / Unknowns

- Exact suspended-account states/transitions surfaced by `SuspendedPage`:
  `NEEDS_CONFIRMATION` (not traced in this pass).

## Relevant Source Files

- `packages/auth/lib/src/session/session_manager.dart`
- `packages/auth/lib/src/presentation/bloc/auth/auth_bloc.dart`
- `packages/auth/lib/src/module/auth_module.dart`
- `packages/auth/lib/src/data/endpoints/auth_api_paths.dart`
- `packages/auth/lib/src/auth/auth_status_notifier.dart`

## Related Documentation

[`../ARCHITECTURE_BLUEPRINT.md`](../ARCHITECTURE_BLUEPRINT.md) ·
[`../SECURITY.md`](../SECURITY.md) ·
[`../../.claude/rules/security.md`](../../.claude/rules/security.md) ·
[`../../.claude/rules/routing.md`](../../.claude/rules/routing.md) ·
[`otp.md`](otp.md)
