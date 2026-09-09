# Documentation Index

First stop for understanding the Sanad monorepo. For coding **rules**, see
[`.claude/rules/`](../.claude/rules/); for the session entry point, see
[`CLAUDE.md`](../CLAUDE.md). Consult the section you need — you should rarely
need to scan source broadly.

## Start Here

| Doc | Read when you need… |
|-----|---------------------|
| [`CLAUDE.md`](../CLAUDE.md) | The session entry point, workflow, and rule map |
| [`docs/ARCHITECTURE.md`](ARCHITECTURE.md) | Monorepo layering & module-system concepts (paths need verification — see note below) |
| [`docs/PACKAGE_GUIDE.md`](PACKAGE_GUIDE.md) | Package structure conventions (paths need verification — see note below) |
| [`docs/FEATURE_GUIDE.md`](FEATURE_GUIDE.md) | Feature folder internal layout & naming (paths need verification — see note below) |
| [`docs/MELOS.md`](MELOS.md) | Monorepo commands, scripts, workspace mechanics |
| [`docs/CONTRIBUTING.md`](CONTRIBUTING.md) | Commit/branch conventions, dev workflow |

> **Source-of-truth note:** the root [`ARCHITECTURE.md`](../ARCHITECTURE.md) is a
> v3.0 narrative that is **partially stale** (package/feature tables predate later
> renames/deletions). For the current package set and layering, trust
> [`dep_rules.yaml`](../dep_rules.yaml) and the `workspace:` list in
> [`pubspec.yaml`](../pubspec.yaml) — never a doc's prose — as the authority.
>
> **⚠️ `packages/features/<name>/` is stale — do not use it.** `docs/ARCHITECTURE.md`,
> `FEATURE_GUIDE.md`, `PACKAGE_GUIDE.md`, `MELOS.md`, `TESTING_GUIDE.md`, and
> `API_GUIDE.md` all describe feature packages at `packages/features/<name>/`.
> That directory does not exist. The current layout is: shared packages at
> `packages/<name>/`, provider-local packages at `apps/<app>/packages/<name>/`,
> app-local features at `apps/<app>/lib/src/features/<name>/`. These docs remain
> useful for **concepts and rationale** (layering, module system, testing
> approach) but are **not canonical for current paths** — verify any path claim
> against the tree, `pubspec.yaml`, or `dep_rules.yaml` before acting on it.

## Architecture

| Doc | Consult for |
|-----|-------------|
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | Structure, Clean Architecture layers, module system |
| [`ARCHITECTURE_BLUEPRINT.md`](ARCHITECTURE_BLUEPRINT.md) | Error handling, retry, offline, API-contract patterns |
| [`ROUTING.md`](ROUTING.md) | go_router setup, guards, per-app routers |
| [`DEPENDENCY_GRAPH.md`](DEPENDENCY_GRAPH.md) | Package dependency edges |
| [`CONFIGURATION.md`](CONFIGURATION.md) / [`FLAVORS.md`](FLAVORS.md) | Env config, dart-defines, flavors |
| [`adr/`](adr/) | Why key decisions were made (see Decisions below) |
| [`ai-chat/`](ai-chat/) | AI chat: wire protocol, agent contract, renderer architecture |
| DI wiring | [`adr/0008-get-it-di.md`](adr/0008-get-it-di.md) + `apps/<app>/lib/src/di/app_di.dart` + each feature's `src/module/*_module.dart` |

## Features

| Doc | Consult for |
|-----|-------------|
| [`features/README.md`](features/README.md) | Index of all client & provider features with locations |
| [`features/app-lock.md`](features/app-lock.md) | Local biometric/device unlock gate over an authenticated session |
| [`features/auth.md`](features/auth.md) | Shared authentication/session vertical |
| [`features/document-flow.md`](features/document-flow.md) | Shared document upload/OCR/review/submit pipeline |
| [`features/organization-settings.md`](features/organization-settings.md) | Provider business-profile / settings flow |
| [`features/registration.md`](features/registration.md) | Provider onboarding + document OCR flow |
| [`features/otp.md`](features/otp.md) | Shared OTP verification widget/flow |
| [`features/ai-chat.md`](features/ai-chat.md) | AI assistant chat with structured UI (**prototype**, dev-only route) |
| [`features/client-requests.md`](features/client-requests.md) | Client request lifecycle: draft, submit, negotiate, confirm |
| [`features/provider-requests.md`](features/provider-requests.md) | Provider request workspace: server-derived tabs, offers, job actions |
| [`features/notifications.md`](features/notifications.md) | Notification inbox, FCM device registration, tap routing (**SSE stream is web-only and not implemented**) |

## API

| Doc | Consult for |
|-----|-------------|
| [`API_GUIDE.md`](API_GUIDE.md) | Data-layer standards: client, DTOs, endpoints, error mapping |
| Live contract | OpenAPI spec at `https://dev-api.trysanad.us/api/docs-json` (dev). Base URLs per env in `AppConfig.network`. |

## Security

| Doc | Consult for |
|-----|-------------|
| [`SECURITY.md`](SECURITY.md) | Token flow, secure storage, auth interceptor, logging limits |
| [`.claude/rules/security.md`](../.claude/rules/security.md) | Actionable do/don't + open items (SSL pinning, WebView) |

## Decisions (ADRs)

| ADR | Decision |
|-----|----------|
| [0001](adr/0001-monorepo-melos.md) | Monorepo with Melos |
| [0002](adr/0002-clean-architecture.md) | Clean Architecture layering |
| [0003](adr/0003-design-system-tokens.md) | Design-system tokens |
| [0004](adr/0004-asset-ownership.md) | Asset ownership |
| [0005](adr/0005-taskeither-result-pattern.md) | fpdart `TaskEither` result pattern |
| [0006](adr/0006-bloc-state-management.md) | BLoC state management |
| [0007](adr/0007-go-router.md) | go_router navigation |
| [0008](adr/0008-get-it-di.md) | get_it dependency injection |
| [0009](adr/0009-ai-chat-ui-protocol.md) | Bespoke semantic UI protocol for AI chat |

New ADRs use [`templates/ADR_TEMPLATE.md`](templates/ADR_TEMPLATE.md).

## Other Guides

[`TESTING_GUIDE.md`](TESTING_GUIDE.md) ·
[`DESIGN_SYSTEM.md`](DESIGN_SYSTEM.md) · [`TYPOGRAPHY.md`](TYPOGRAPHY.md) ·
[`LOCALIZATION_GUIDE.md`](LOCALIZATION_GUIDE.md) ·
[`PERFORMANCE_GUIDE.md`](PERFORMANCE_GUIDE.md) ·
[`ANALYTICS_EVENTS.md`](ANALYTICS_EVENTS.md) · [`RELEASE.md`](RELEASE.md)
