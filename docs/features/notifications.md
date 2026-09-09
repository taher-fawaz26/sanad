# Notifications and Mobile Push

The in-app notification inbox, the FCM device-token lifecycle, and the shared
tap routing that turns a notification into a screen.

**Package:** [`packages/notifications`](../../packages/notifications) (tier 2)

---

## Scope: the SSE stream is web-only and is not implemented

The backend offers three delivery channels for the same events:

| Channel | Purpose | Mobile? |
|---|---|---|
| In-app list (`GET /notifications`) | Durable history | **Yes** |
| FCM push | Background and killed delivery | **Yes** |
| SSE (`/notifications/stream`) | Live updates while foregrounded | **No — web only** |

`POST /notifications/stream-ticket`, `GET /notifications/stream?ticket=`,
`EventSource`, ticket-refreshing reconnect logic, the 15-minute server close and
the 8-connection cap are **deliberately not implemented and not tested**.
Nothing in this package opens a connection.

What replaces it on mobile: FCM delivers while the app is backgrounded, and
screens re-read their resource when they become active, on pull-to-refresh, on
app resume, and after any mutation. That also covers the transitions the server
makes on timers rather than in response to a tap — see
[client-requests.md](client-requests.md#server-owned-state).

---

## One Firebase boundary

`firebase_messaging` is imported by exactly one file:
`data/platform/firebase_push_messaging_gateway.dart`, behind the
`PushMessagingGateway` port. That is what makes every other push concern —
registration, routing, deduplication — unit-testable with a plain fake and free
of a Firebase binary dependency. It mirrors how `packages/permissions` confines
`permission_handler`.

Each app calls `Firebase.initializeApp` exactly once, in its bootstrap.

---

## Device-token registration

| Method | Path | Result |
|---|---|---|
| `POST` | `notifications/devices` | `204` |
| `DELETE` | `notifications/devices/:token` | `204`, idempotent |

Body: `{"token": "...", "platform": "IOS" | "ANDROID"}`. The apps never send
`WEB`.

**Registration is an upsert, not a setup step.** `PushRegistrationCoordinator`
is the single owner and runs on four triggers:

1. **After every login** — `SessionManager.onSessionStarted`, fired from `save()`.
2. **On every launch with a live session** — the same hook, fired from
   `restore()`. Without this the server eventually prunes the token as stale.
3. **On every token rotation** — one `onTokenRefresh` subscription. `start()` is
   idempotent, so a re-entered bootstrap cannot produce duplicate callbacks.
4. **Before logout** — `SessionManager.onBeforeSessionEnd`.

### The logout seam

`SessionManager` gained two additive, default-null parameters:

- `onSessionStarted` — a session became usable (login, or a launch that restored
  one). Unlike the pre-existing `onSessionBoundary`, it does not fire on logout.
- `onBeforeSessionEnd` — **awaited at the top of `clear()`, before the tokens are
  wiped**, so the `DELETE` is still authenticated. It is time-boxed to 3 seconds
  and swallows every error: `clear()` is also reached fire-and-forget from the
  401-refresh-failure handler, where the token is already dead, and a logout must
  never be blocked by a cleanup call.

One seam covers all four session-ending paths: `AuthBloc._logout`, the 401
handler, `AppLockGate` logout and `DeletionOtpVerifier`.

Tokens belong to devices, not users. Without the unregister, a signed-out
handset keeps receiving the next user's notifications.

The coordinator persists the **last registered token** and deletes that one,
rather than asking the SDK at logout time: if the token rotated in between,
asking would delete the wrong one and leave the real registration live.

---

## Payload and navigation

`GET /notifications` rows now carry three fields, all **nullable** on
notifications that predate deep links:

- `subjectType` — `CLIENT_REQUEST` or `REQUEST_OFFER`
- `subjectId` — the target to open
- `metadata` — display and routing extras (`requestId`, `offerId`, `serviceName`)

`NotificationType` and `NotificationSubjectType` both fall back to `unknown`, so
an older row still parses and still renders — the server already wrote its title
and body in the recipient's language.

### Subject parsing is shared; destinations are not

`NotificationSubject` resolves the coordinates once, in the package, so a client
and a provider cannot drift on what a subject means:

- `CLIENT_REQUEST` → `subjectId` **is** the request.
- `REQUEST_OFFER` → `subjectId` is the **offer**; the request comes from
  `metadata.requestId`.

Each app supplies a `NotificationNavigator` for the destination:

| Subject | Client | Provider |
|---|---|---|
| `CLIENT_REQUEST` | `/requests/:id` | `/requests/:id` |
| `REQUEST_OFFER` | `/requests/:requestId?offer=:offerId` | `/requests/:requestId` |

**An offer opens inside its request, never on a standalone offer screen.** An
offer has no meaning detached from the request it negotiates. On the provider
side there is nothing further to disambiguate — one thread per request.

`metadata.requestId` is optional in the contract, so a `REQUEST_OFFER` without
it is **not navigable** and falls back to the inbox rather than guessing that
`subjectId` is a request id.

### Deduplication

The same event can reach a device twice — a foreground push and then the tap
that reopens the app, or a push and the inbox row. `NotificationDedupStore`
keys on the **stable server notification `id`**, never a timestamp or a locally
generated value, and persists it: the two deliveries can straddle a process
death.

Display and navigation are namespaced separately (`show:` / `nav:`) so drawing a
foreground banner does not consume the dedup slot for the tap that follows it.

A delivery with no id cannot be deduplicated and is always treated as new —
acting twice is better than silently swallowing a real notification.

The store is cleared at every session boundary, so one account's handled ids
cannot suppress another's on a shared device.

### Delivery paths

All three converge on `PushNotificationRouter`:

- **Foreground** → displayed via `flutter_local_notifications`; a tap on that
  banner re-enters the same routing path.
- **Backgrounded, tapped** → `onMessageOpenedApp`.
- **Terminated, tapped** → `getInitialMessage()` on cold start.

`requestStateChanged` emits when a push says a request moved, so an open screen
can re-read. The frame is a signal, not the resource: the payload is minimal and
role-neutral, while the full request differs by who is asking.

---

## Native setup

| | `sanad_client` | `sanad_provider` |
|---|---|---|
| `firebase_core` + `firebase_options.dart` | ✅ | ✅ |
| Android `google-services.json` | ✅ | ✅ |
| Google Services Gradle plugin | ✅ | ✅ |
| `POST_NOTIFICATIONS` permission | ✅ | ✅ |
| iOS `GoogleService-Info.plist` | ❌ **missing** | ❌ **missing** |
| iOS `aps-environment` entitlement + `UIBackgroundModes` | ❌ **missing** | ❌ **missing** |

Android push is fully wired. **iOS push cannot work until the two plist files and
the APNs auth key are added** — those come from the Firebase console and are not
in the repository.

The OS notification permission is requested through
`Permissions.ensureNotifications()`, never by the messaging SDK, so it goes
through the same rationale/settings flow as every other permission.

---

## Routes

`/notifications` — `NotificationsPage`, registered by `NotificationsModule` in
both apps and listed in each app's protected-route set.

---

## Tests

`packages/notifications/test/` — 61 tests covering DTO parsing (including a row
with no subject at all), subject routing, registration on login/launch/refresh,
logout unregistration (including that logout still completes when it fails or
hangs), single-listener idempotence across a simulated relaunch, dedup across a
process restart, and the three delivery paths.

`packages/auth/test/src/session/session_manager_test.dart` covers the two new
lifecycle hooks.

**No tests exist for the SSE stream, by design.**
