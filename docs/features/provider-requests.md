# Provider Request Workspace

Client requests matched to this provider's branches: a tabbed feed with badge
counts and headline stats, one negotiation thread per request, and the job
actions that close it out.

**Feature:** `apps/sanad_provider/lib/src/features/requests/`
**Shared contract:** [`packages/requests_core`](../../packages/requests_core)
**Client counterpart:** [client-requests.md](client-requests.md)

---

## The payload boundary

The provider API returns a **different shape** from the client API, and this is
a privacy boundary rather than a convenience:

- **Rival offers are never sent.** There is no `threads` array — only
  `myOffers`, this provider's own thread.
- **Contact details are withheld until the booking is won.** While
  `contact.unlocked` is `false`, `clientName`, `clientPhone`, `addressLine`,
  `lat` and `lng` are all `null`.
- **Location is one coarse `areaName`** before unlock. One area, not every
  overlapping one — listing them all would pinpoint the client more precisely
  than naming one.

`ProviderRequest` is therefore a separate model from the client app's
`ClientRequest`, not a shared one with fields blanked out. Sharing one model
across both roles is exactly the mistake that would leak either.

> **`contact.unlocked` is the single source of truth for visibility.**
> `GatedContactCard` branches on it and on nothing else — not the request
> status, not `myOfferStatus`, not "are the fields populated". A missing
> contact block reads as locked: fail closed on an ambiguity.

---

## The tab is server-derived

`tab` is computed by the backend from the request status **and** this provider's
own offer thread. The device cannot reproduce it: the same `SUBMITTED` request
is `NEW` to a provider that has not bid, `AWAITING_CLIENT` to one that has, and
`YOUR_TURN` to one the client has countered.

It is also a **server-side filter**. A paginated feed cannot be re-bucketed
after the fact without invalidating the per-tab counts, so `tab` goes on the
query string and `ProviderRequestCounts` comes from its own endpoint.

Tabs: `NEW`, `AWAITING_CLIENT`, `YOUR_TURN`, `SCHEDULED`, `IN_PROGRESS`,
`TO_CONFIRM`, `CLOSED`.

Stats: `needsYourOffer`, `awaitingClient`, `scheduledToday`,
`completedThisMonth` — the last replaces an earnings tile, since no money passes
through the platform in this release.

---

## Endpoints

| Method | Path | Use case |
|---|---|---|
| `GET` | `provider/requests` | `ListProviderRequestsUseCase` |
| `GET` | `provider/requests/counts` | `GetProviderRequestCountsUseCase` |
| `GET` | `provider/requests/stats` | `GetProviderRequestStatsUseCase` |
| `GET` | `provider/requests/:id` | `GetProviderRequestUseCase` |
| `POST` | `provider/requests/:id/offers` | `CreateProviderOfferUseCase` |
| `POST` | `provider/requests/:id/complete` | `CompleteProviderJobUseCase` |
| `POST` | `provider/requests/:id/cancel` | `CancelProviderJobUseCase` |
| `POST` | `provider/offers/:offerId/withdraw` | `WithdrawProviderOfferUseCase` |
| `POST` | `provider/offers/:offerId/accept` | `AcceptClientCounterUseCase` |
| `POST` | `provider/offers/:offerId/decline` | `DeclineClientCounterUseCase` |
| `POST` | `provider/offers/:offerId/counter` | `CounterClientOfferUseCase` |

Note the asymmetry with the client side: creating an offer and the job actions
are nested under a **request**, while acting on an existing offer is addressed by
**offer id alone**. A provider has one thread per request, so the offer id is
already unambiguous.

### Every mutation re-reads the request

The provider mutation endpoints do not document a response body. More
importantly, accepting a client's counter *unlocks the contact block* and
changes the whole shape of what this provider may see. So
`ProviderRequestsRepositoryImpl` performs the action and then re-reads
`GET /provider/requests/:id`.

A failed action short-circuits, so the caller sees the action's own failure —
including the `409` for an exhausted re-bid budget — rather than a misleading
read error.

---

## The re-bid budget

`remainingRebids` is how many further offers this provider may make on a
request. **Withdrawing consumes one** — send-and-withdraw is not a free retry,
which is why the withdraw affordance confirms first and says so.

At zero, creating another live root offer answers `409`.
`ProviderRequest.canSendOffer` gates the button, but the server stays
authoritative and the conflict is still surfaced.

---

## Permissions

Backend-issued strings, declared in `ClientRequestPermissions` as plain
`static const String` — never an enum, because the backend adds actions without
a client release.

| Permission | Gates |
|---|---|
| `provider:client-request:view` | Counts, stats, list, detail — and the bottom-nav tab |
| `provider:client-request:offer` | Create, withdraw, accept, decline, counter |
| `provider:client-request:complete` | Complete, cancel |

Route gating lives in `provider_route_permissions.dart` (both surfaces need only
`view`); the write affordances are wrapped in `PermissionGate` on the detail
screen, because a manager may legitimately read a workspace they cannot bid in.

`RouteAuthorizationTable` is first-match-wins: the literal `/requests` rule is
registered ahead of the `^/requests/[^/]+$` pattern.

---

## Routes

| Path | Screen |
|---|---|
| `/requests` | `ProviderRequestsPage` — the workspace |
| `/requests/:id` | `ProviderRequestDetailPage` |

Contributed through `ProviderRequestsModule.shellRoute()`, **not** through
`routes()`. `/requests` is a bottom-nav branch, and registering it both ways
shadows the branch on first visit — `StatefulNavigationShell` re-matches the
whole tree then, and the top-level registration wins, rendering the page outside
the shell with no bottom nav bar. Same precedent as `ServicesModule`.

---

## Server-owned state

As on the client side, the app does not open the SSE stream and never predicts a
status. The workspace re-reads the feed **and** the counts together on
pull-to-refresh, on app resume, after any mutation, and on returning from a
detail screen — every one of those can move a request between tabs.

---

## Localization

`provider_requests.*` for this feature, `requests.*` for the shared lifecycle
vocabulary. `serviceName`, `areaName` and a client's dispute reason are rendered
verbatim. The client's phone number is rendered through
`AppKeyValueCard(isLtr: true)` so its leading `+` does not jump to the visual end
under an RTL locale.

---

## Tests

`apps/sanad_provider/test/features/requests/` — 44 tests covering DTO
round-trips, the tab being read rather than derived, contact gating (including
that an accepted offer on an in-progress request does *not* imply unlock),
counts and stats, the URL contract, the re-bid budget, offer and job actions,
server-side search debounce, and the mutation re-read.
