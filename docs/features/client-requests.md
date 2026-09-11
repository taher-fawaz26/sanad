# Client Requests

The client half of the service-request lifecycle: draft → submit → receive
offers → accept / reject / counter → job runs → confirm or dispute.

**Feature:** `apps/sanad_client/lib/src/features/client_requests/`
**Shared contract:** [`packages/requests_core`](../../packages/requests_core)
**Provider counterpart:** [provider-requests.md](provider-requests.md)

---

## Lifecycle

```text
DRAFT ──submit──▶ SUBMITTED ──accept offer──▶ SCHEDULED ──▶ IN_PROGRESS
                      │                                          │
                      │ (timer)                                  │ provider
                      ▼                                          ▼ completes
                   EXPIRED                            AWAITING_CONFIRMATION
                                                          │            │
                                              confirm ────┘            └──── dispute
                                                  ▼                            ▼
                                              COMPLETED                    DISPUTED
```

`CANCELLED` is reachable from any live state, by either side.

### Transitions nobody tapped

Three transitions happen on **server timers**, with no user action:

| From | To |
|---|---|
| `SUBMITTED` | `EXPIRED` |
| `SCHEDULED` | `IN_PROGRESS` |
| `AWAITING_CONFIRMATION` | `COMPLETED` |

The app therefore **never predicts a status**. Every mutation adopts the request
the server returns, and screens re-read on activation, on pull-to-refresh, on
app resume, and when a push signals a change. See
[Server-owned state](#server-owned-state).

---

## Endpoints

All paths are relative — the configured base URL already ends in `/api/v1/`.

| Method | Path | Use case |
|---|---|---|
| `GET` | `requests` | `ListClientRequestsUseCase` |
| `POST` | `requests` | `CreateDraftRequestUseCase` |
| `GET` | `requests/:id` | `GetClientRequestUseCase` |
| `PATCH` | `requests/:id` | `UpdateDraftRequestUseCase` |
| `POST` | `requests/:id/submit` | `SubmitRequestUseCase` |
| `POST` | `requests/:id/cancel` | `CancelClientRequestUseCase` |
| `POST` | `requests/:id/confirm` | `ConfirmClientRequestUseCase` |
| `POST` | `requests/:id/dispute` | `DisputeClientRequestUseCase` |
| `POST` | `requests/:id/offers/:offerId/accept` | `AcceptOfferUseCase` |
| `POST` | `requests/:id/offers/:offerId/reject` | `RejectOfferUseCase` |
| `POST` | `requests/:id/offers/:offerId/counter` | `CounterOfferUseCase` |

Plus the read-only catalogue the composer picks from: `GET services`,
`GET categories`.

**Every offer action carries both ids.** The backend enforces that `offerId`
belongs to the `:id` in the URL and answers `404` on a mismatch, so the
repository signature takes both and makes that impossible to get wrong.

---

## Drafts are meant to be incomplete

`POST /requests` validates nothing beyond field shapes. Completeness is enforced
only at submit. Two consequences the code depends on:

- Almost every field on `ClientRequest` is **nullable** — `serviceId`,
  `serviceName`, `categoryId`, `categoryName`, the location fields and every
  timestamp but `createdAt`. Treating any of them as required would make the app
  unable to read back a draft it had just created.
- `SaveClientRequestRequest` **omits** every field the user has not set. Sending
  `null` would clear a value saved earlier.

`mediaIds` is the one exception: the backend treats it as a *replacement* for
the whole attachment set, so it is sent only once the composer has a real set
(`RequestDraftState.mediaIdsResolved`). An unrelated save must not detach files
by sending `[]`.

Submit requires `serviceId`, a location (`lat`/`lng`) and `preferredAt`.
`RequestDraftState.canSubmit` gates the button; the server re-validates.

> **Timestamps carry an explicit offset.** `ApiDateTime.encode` normalises to
> UTC before serializing. `DateTime.toIso8601String()` on a *local* value emits
> no zone at all, which the backend reads as UTC — four hours out in Gulf
> Standard Time.

---

## Structured submission conflicts

`POST /requests/:id/submit` answers `409` with a `code` when matching finds
nothing. Each code implies a different next action, which is the whole reason
the backend distinguishes them:

| Code | What the UI offers |
|---|---|
| `NO_PROVIDERS_FOR_SERVICE` | "Change service" → reopens the service picker |
| `NO_COVERAGE` | "Change address" → reopens the location picker |
| `OUTSIDE_HOURS` | `alternatives` rendered as one-tap retry chips |

Read it with `RequestSubmissionConflict.tryParse(failure)`. Nothing had to
change in the transport layer for this: `ErrorMapper` already preserves the
whole 409 body in `Failure.metadata`, and `Failure.backendCode` reads the code
out of it. `Failure.code` still carries the HTTP status, because
`isRetryable` parses it as an int.

Picking a new service, address or time clears the banner — that *is* the
recovery action.

---

## Negotiation

`threads` holds one negotiation per provider, offers **oldest first**. Exactly
one offer in a live thread is `PENDING`, and its `actorType` is the whole
turn-taking rule:

- pending + `PROVIDER` → the client's turn (`thread.isAwaitingClient`)
- pending + `CLIENT` → the provider's turn (`thread.isAwaitingProvider`)

Nothing derives whose turn it is from the request status.

Outcomes that read differently and must stay distinct:

- **`LOST`** — another provider won; this one was never personally judged.
- **`REJECTED`** — the client explicitly declined this offer.
- **`SUPERSEDED`** — the offer was *countered*, not refused.

Accepting books the job, sets `scheduledAt`, and marks rival offers `LOST`.
Rejecting ends one thread only.

---

## Server-owned state

The mobile apps do **not** open the backend's SSE notification stream — that is
a web delivery channel (see [notifications.md](notifications.md)). Freshness
comes from re-reading instead:

- on screen activation and when returning from a pushed screen,
- on pull-to-refresh,
- on app resume (`didChangeAppLifecycleState`),
- after every mutation (the response *is* the new state),
- when a push says this request moved (`PushNotificationRouter.requestStateChanged`).

A `409` on any action additionally forces a re-read: it almost always means the
server state moved underneath the view — a rival accepted, or a timer fired.

`PATCH /requests/:id` answers `409` once an offer is awaiting a reply. The UI
surfaces that and stops treating the request as editable rather than retrying.

---

## The list screen: three tabs, two sections

Figma `Requests - Active` (`8135:29516`) splits the list into **Active**,
**Scheduled** and **Cancelled**, and each tab into a flagged run under
"Needs your attention" followed by the tab's own heading.

A tab is not a status. Scheduled and Cancelled each map onto exactly one
server status and are filtered **server-side** (`GET /requests?status=`) —
the only way a paginated list can filter correctly, since filtering a loaded
page would show an arbitrary subset of the matches and an incorrect "no more"
state.

Active cannot: it spans five statuses and the endpoint takes one. It reads
unfiltered and drops only the two statuses the other tabs own. The cost is
bounded and visible — a page of mostly scheduled or cancelled rows renders
short and the user pulls for more — and it is preferred to sending a repeated
`status` parameter the backend has not been observed to accept. A completed,
disputed or expired request still appears, under Active's "Other requests":
nothing becomes unreachable in a three-tab design.

Which rows are flagged comes from `ClientRequest.needsAttention`, which is the
existing action-availability getters read as one question — an unfinished
draft, a finished job awaiting confirmation, or an offer whose turn is the
client's. The card's trailing pill (Figma's `missing address`) names which,
from `missingForSubmit`.

The screen has **no create, add or edit affordance**, by product rule: a
request is created by asking the agent in AI Chat. Cancel, Open Chat, Rebook
and opening the detail screen are the only actions the card offers, and all of
them already existed.

---

## Routes

| Path | Screen |
|---|---|
| `/requests` | `ClientRequestsPage` — the three-tab list (see below) |
| `/requests/new` | `RequestComposerPage` — create |
| `/requests/:id` | `ClientRequestDetailPage` — detail and negotiation |
| `/requests/:id/edit` | `RequestComposerPage` — edit |

`/requests/:id?offer=<offerId>` highlights one thread — where a `REQUEST_OFFER`
notification lands. An offer has no screen of its own.

Registered by `ClientRequestsModule` **unconditionally**, unlike the debug-only
AI-chat prototype: a push must be able to open a request in a shipped build.

---

## Localization

`client_requests.*` for this feature's copy, `requests.*` for the lifecycle
vocabulary and validator messages shared with the provider app. Backend-supplied
strings — `serviceName`, `areaName`, a dispute or cancel reason — are rendered
**verbatim**; the server localizes them from `x-lang`.

---

## Tests

`apps/sanad_client/test/features/client_requests/` — 61 tests covering DTO
round-trips (including an all-null draft), the endpoint/URL contract, the three
409 codes and their recovery, offer accept/reject/counter, thread correlation,
pagination and the `limit ≤ 100` cap.
