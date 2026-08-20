# Features Index

Maps every business feature to its location. For the internal **layer
structure** of a feature (domain/data/presentation, naming), see
[`../FEATURE_GUIDE.md`](../FEATURE_GUIDE.md) — its top-level package **paths**
are stale (`packages/features/...` does not exist); see the stale-path warning
in [`../../CLAUDE.md`](../../CLAUDE.md).

Features live as: app-local folders (`apps/<app>/lib/src/features/<name>/`),
provider-local shared packages (`apps/sanad_provider/packages/<name>/`), or
cross-app shared packages (`packages/<name>/`, e.g. `auth`, `otp`,
`document_flow`). Each has a `src/{domain,data,presentation}` plus `di/`,
`module/`, `routes/`.

Docs marked **detailed** below have a dedicated page verified against source.
Others are listed with an accurate location + one-line purpose; treat deeper
behavioral claims as `NEEDS_CONFIRMATION` until a dedicated page is written.

## Sanad Provider (`apps/sanad_provider/lib/src/features/`)

| Feature | Purpose | Doc |
|---------|---------|-----|
| `registration` | Provider onboarding + document (Emirates ID / trade licence) OCR review | **[detailed](registration.md)** |
| `organization_settings` | Business profile, identity, categories, social, working hours, legal docs | **[detailed](organization-settings.md)** |
| `home` | Provider home/dashboard shell tab | location only |
| `requests` | Incoming service requests | location only |
| `messages` | Messaging tab | location only |
| `schedule` | Availability calendar | location only |
| `availability` | On/off-duty state | location only |
| `services` (feature) | Provider-facing services UI | location only |
| `profile` | Provider-specific profile | location only |
| `invitation` | Worker/team invitation flow | location only |

### Provider shared packages (`apps/sanad_provider/packages/`)

| Package | Purpose |
|---------|---------|
| `branches` | Branch management (incl. `BranchScheduleFormatter`) |
| `services` | Services domain/data shared across provider features |
| `workers` | Worker management + invitations |
| `provider_rbac` | Provider role/permission definitions (feeds `authorization`) |

## Sanad Client (`apps/sanad_client/lib/src/features/`)

| Feature | Purpose | Doc |
|---------|---------|-----|
| `home` | Client home/dashboard | location only |
| `booking` | Browse & book services | location only |
| `services` | Service catalogue | location only |
| `orders` | Order history/status | location only |
| `offers` | Promotional offers | location only |
| `favorites` | Saved services | location only |
| `wallet` | Payment wallet | location only |
| `support` | In-app support | location only |
| `profile` | Client-specific profile | location only |

## Shared feature packages (`packages/`)

| Package | Purpose | Doc |
|---------|---------|-----|
| `otp` | OTP verification view/bloc (login & registration) | **[detailed](otp.md)** |
| `auth` | Authentication vertical (login, session, splash) | **[detailed](auth.md)** |
| `account_settings` | Account credentials & settings shared UI | location only |
| `contact_verification` | Phone/email verification | location only |
| `document_flow` | Generic document capture/extraction/review pipeline | **[detailed](document-flow.md)** |
| `media_upload` / `media` | Multipart upload pipeline & media types | location only |
| `authorization` | RBAC evaluation/gating leaf | see [../.claude/rules/routing.md](../../.claude/rules/routing.md) |
