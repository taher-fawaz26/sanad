# Ticket — Emit SANAD Chat UI Protocol v1 from the AI agent

**Type:** Feature · **Component:** AI agent / chat backend
**Depends on:** nothing in the mobile app — the client side is complete and frozen
**Contract:** [`AI_CONTRACT.md`](AI_CONTRACT.md) (implement against this)
**Reference:** [`PROTOCOL_V1.md`](PROTOCOL_V1.md) (what the client enforces)

---

## Summary

The SANAD mobile client can render structured, native UI inside an assistant
chat bubble — cards, buttons, lists, and five business-domain components — from
a JSON payload. The renderer, validator, action registry and a scripted mock
transport are implemented and tested.

This ticket covers the agent side: producing those payloads.

**Scope of this ticket is payload generation only.** Transport is a separate
ticket (see §7) — the client currently consumes a local mock and has no socket.

---

## Why the payload is shaped the way it is

- The agent **describes intent**; the app decides how it looks. There is no way
  to express a widget, a colour, a pixel value or a font.
- The agent **cannot cause an action** — only request one from a fixed catalog.
  The app decides whether it is allowed and what it does.
- Payloads are **untrusted input** and validated before rendering. Anything
  invalid degrades that bubble; the chat never breaks.

---

## 1. Deliverables

1. Agent emits protocol-v1 `ui` payloads alongside its text, per
   `AI_CONTRACT.md`.
2. Agent streams text as `text_delta` events and closes with an authoritative
   `message_end.text`.
3. Server-side validation of every payload before it leaves the backend
   (§4) — the client's validation is a safety net, not a substitute.
4. A payload fixture suite the mobile team can replay (§6).
5. Agreement on the asset-id list (§3.3) and the semantic-card entity ids (§3.2).

---

## 2. Event sequence to produce

One assistant turn:

```json
{"eventId":"evt_1","conversationId":"conv_9","messageId":"msg_7","seq":0,"type":"message_start","payload":{"role":"assistant"}}
{"eventId":"evt_2","conversationId":"conv_9","messageId":"msg_7","seq":1,"type":"text_delta","payload":{"delta":"I found "}}
{"eventId":"evt_3","conversationId":"conv_9","messageId":"msg_7","seq":2,"type":"text_delta","payload":{"delta":"3 services near you."}}
{"eventId":"evt_4","conversationId":"conv_9","messageId":"msg_7","seq":3,"type":"ui","payload":{"schemaVersion":1,"blocks":[...]}}
{"eventId":"evt_5","conversationId":"conv_9","messageId":"msg_7","seq":4,"type":"message_end","payload":{"text":"I found 3 services near you."}}
```

Hard requirements:

- `eventId` non-empty on every frame.
- All frames for one turn share one `messageId`.
- `message_end.text` is the **complete final text**, not the last fragment. The
  client uses it to repair a dropped delta.
- At most one `ui` event per message.
- `typing` and `error` may be sent at any time.
- Do not send `tool_status` — reserved, currently ignored.

---

## 3. Payload rules the agent must satisfy

Full detail in `AI_CONTRACT.md`. The points most likely to be got wrong:

### 3.1 `schemaVersion` is an integer
`{"schemaVersion": 1}`, never `"1"`. A string rejects the entire payload. This
is the single highest-frequency failure mode — assert it in the emitter.

### 3.2 Prefer the seventeen semantic components
Entity cards: `service_card`, `appointment_card`, `branch_card`, `order_card`,
`provider_card`, `document_card`. Summaries: `booking_summary`,
`request_summary`, `payment_receipt`. Interactive: `quick_reply`, `time_slots`,
`review_request`, `location_picker`. Prompts: `permission_request`,
`media_request`, `location_confirm`, `reminder_card`.

Do **not** rebuild any of them from `row`/`column`/`text`, and do **not**
invent a type name or a generic `{"type": "custom_card", "data": {...}}` — an
unknown type renders as its `fallbackText` and nothing else.

The entity cards carry the real entity id (`serviceId`, `appointmentId`,
`branchId`, `orderId`, `providerId`, `documentId`). **Action required:**
confirm with the mobile team that the ids the agent has are the ids the app can
open.

These seventeen are the complete semantic set. No provider-domain components
exist. `document_card` is still supported but is **not in the current design
set** — prefer `order_card` or a summary for new work.

**Action required:** confirm the agent can generate reliably against a
32-type catalog (15 primitives + 17 semantic). If adherence suffers, the fix is
prompt-side grouping — tell it which four or five types this conversation can
use — not a smaller catalog.

### 3.3 Images: `url` for dynamic media, `assetId` for static illustrations

Every image in the protocol is the same object, in every node that has one
(`image`, `list_item.leadingImage`, `service_card.image`,
`provider_card.image`, `permission_request.image`,
`location_confirm.image`):

```json
{"url": "https://cdn.example.com/services/ac.jpg", "assetId": "service_tools"}
```

```text
url > assetId > the component's own no-image state
```

Both fields are optional; **when both are present the client uses the URL**,
and the `assetId` is only the fallback if the download fails. An empty `url`
(`""`) counts as absent and falls through to the asset.

**Send `url` for anything backend-owned** — service photos, provider
portraits, business and order artwork. The client loads it through its existing
cached-network-image stack. Requirements:

* **https only.** A non-https URL, an embedded userinfo (`https://u:p@host/`)
  or an unparseable URL is refused during validation; no request is made.
* The client currently accepts **any https host** and can be narrowed to an
  allowlist in one line. **Action required:** tell the mobile team the origins
  you serve images from, so that narrowing can happen without breaking you.
* Do not send `http`, data URIs, local paths, or anything that is not a plain
  https URL to an image.

**`assetId` is an allowlist**, not a free field. The published ids:
`image_placeholder`, `empty_state`, `service_tools`, `no_branch_locations`,
`ai_map_preview`. Anything else is dropped with `unknown_asset_id`. It must
never be a Flutter asset path, a package path, an Android/iOS resource name or
a filename — the client matches the string against its catalog and nothing
else, and it alone decides which bundled file an id means.

**Action required:** agree any additional `assetId` values with the mobile
team; publishing one is a client release. Do **not** build a local asset
catalog for dynamic business media — that is what `url` is for.

### 3.4 Eleven actions are implemented
`send_message`, `open_service`, `open_appointment`, `open_branch`,
`open_document`, `copy_text`, `request_location_share`, `request_image_upload`,
`request_permission`, `call_phone`, `open_map`.

`open_url`, `open_route` and `dismiss` are defined in the protocol but **no
client implements them**: there is no URL allowlist, no symbolic route map, and
a card that can be dismissed closes itself. A control using any of the three is
dropped entirely. Do not emit them.

`call_phone` opens the dialer **pre-filled** — it never dials, so the user
always sees the number first. `open_map` takes an address or `"lat,lng"`, not a
URL; that boundary is what lets `open_url` stay closed. **Action required:**
decide whether the numbers reaching `call_phone` should come from a
server-side allowlist.

### 3.4a Cards carry their own buttons
Most semantic cards accept `actions`: up to three
`{"label", "action", "variant"?, "intent"?}` entries drawn inside the card.
An entry whose action is not implemented is dropped on its own; the card
survives. `quick_reply`, `time_slots`, `review_request` and `location_picker`
do not take `actions` — they own their controls.

### 3.4b The interactive components send back text
`time_slots`, `review_request` and `location_picker` hold the user's input in
the app and submit it as a `send_message` built from a template **you** supply:
`confirmTemplate` / `submitTemplate` with one placeholder — `{slot}`,
`{comment}` or `{location}`. What arrives on the turn is ordinary user text.
Design the templates so the resulting sentence is one you can parse.

### 3.5 Structured values, localized prose
Send `price` as `{"amount": 100, "currency": "AED"}`, `startsAt` as ISO-8601
UTC, `distanceMeters` as a number in metres. The client formats all three for
the reader's language, currency conventions and clock.

Send `title`, `subtitle`, `text` **already localized** in the user's language.
The app does not translate payload text. English is the product default and
Arabic is a first-class RTL locale, so the language comes from the turn, not
from an assumption.

Mark an inherently-LTR value — a reference id, a card number, a phone number —
with `"isLtrValue": true` on the detail item (or `"direction": "ltrValue"` on a
`text` node) so an Arabic line cannot reorder it.

### 3.6 `fallbackText` on every semantic node
An installed app may be older than the agent. A node type the client does not
know renders its `fallbackText`, or vanishes if there is none. This is the only
backward-compatibility mechanism — there is no capability negotiation.

### 3.7 Never emit
Flutter/Dart code, Markdown used as UI (tables, headings, bullet lists,
links), `onTap`/callbacks/method names, raw route paths, deep links, hex
colours, pixel sizes, font names.

---

## 4. Server-side validation (required)

Reject or repair before sending. Mirror these client rules:

- `schemaVersion == 1` (integer)
- every `type` is one of the 32 documented node types (15 primitives + 17
  semantic)
- every action `type` is one of the eleven implemented
- required fields present: `text`, `label`, `alt`, `title`, entity ids,
  `startsAt`, `permission`, `confirmLabel`/`confirmTemplate`,
  `submitLabel`/`submitTemplate`, `quick_reply.options ≥ 2`,
  `time_slots.slots ≥ 2`, summary/receipt `items ≥ 1`
- `permission` is one of `camera`/`photos`/`microphone`/`location`/
  `notifications` — anything else drops the card
- every `image.url` is https, has no userinfo, and is parseable
- every `image.assetId` is in the published catalog — never a path
- limits: **32 KB** payload, **100** nodes, depth **6**, 12 blocks, 12
  column/card children, 8 row children, 20 list children, 20 spans, 12 actions,
  8 images, text ≤ 2000, labels ≤ 64, chip/badge/status labels ≤ 40, 3 card
  actions, 8 detail items, 12 slots, 6 saved locations, 4 media options,
  4 provider stats

Payload-size and node-count overruns cause the client to reject the **whole**
payload, so the user loses the structured part of the answer. Catch those
server-side.

---

## 5. Behaviour to expect from the client

Useful when debugging why something did not appear:

| Agent sends | Client does |
|---|---|
| Unknown node type + `fallbackText` | renders the text |
| Unknown node type, no `fallbackText` | drops it silently |
| Unsupported action on a button | drops the whole button |
| Unsupported action on a chip | keeps the label, removes the tap |
| Unsupported action in a card's `actions` | drops that entry, keeps the card |
| `permission` the client does not know | drops the whole `permission_request` |
| `selectedSlotId` naming no slot | renders the grid unselected |
| `image.url` that is https and allowed | loads it, cached, with a shimmer then the image |
| `image.url` refused by the policy | falls back to `assetId`, or shows the no-image state; no request |
| `image.url` that 404s or times out | shows the `assetId` if you sent one, else the no-image state |
| Both `url` and `assetId` | uses the **URL** |
| Unknown `assetId`, no url | drops the image |
| Unknown enum value | uses the documented default |
| Unknown property | ignores it |
| Over a child/depth limit | truncates that container |
| Over size/node limit | drops the whole payload, keeps the prose |
| Malformed JSON | drops the whole payload, keeps the prose |

The chat never breaks. It also never tells the user something was dropped — so
a silently missing card is the symptom to look for.

---

## 6. Fixtures to deliver

A replayable set the mobile team can point the client at, covering at minimum:

1. plain streamed text, no `ui`
2. text + `card` + `button`
3. three `service_card`s with prices
4. `appointment_card` + two action buttons
5. `branch_card` list with statuses and distances
6. a primitives sampler (`row`, `column`, `divider`, `chip`, `icon`,
   `rich_text`, `progress`, `list`)
7. `quick_reply` with 2–6 options
8. two `order_card`s — one delivered, one active with a `Track` action
9. a `provider_card` with stats and `Call` / `Message`
10. `booking_summary`, `request_summary` and `payment_receipt` (one succeeded,
    one declined)
11. `time_slots` with a pre-selected slot and a disabled one
12. `review_request` and `location_picker` — check the template placeholders
    come back substituted on the next turn
13. `permission_request` for `camera` and for `location`, plus `media_request`
    and `location_confirm`
14. `reminder_card` in `warning` and in `error`
15. several semantic cards in **one** reply
16. a node type the client does not know, **with** `fallbackText`
17. an unsupported action, including one inside a card's `actions`
18. a deliberately malformed payload
19. a payload exceeding size/depth/child limits
20. a long streaming reply (60+ deltas) plus a `ui` event

The mobile prototype already ships equivalents in
`apps/sanad_client/lib/src/features/ai_chat/src/data/mock_scenarios.dart` and
`data/scenarios/component_scenarios.dart` — match those shapes so both sides
test the same things. The client's dev build renders every one of them at
`/dev/ai-chat/showcase`, which is the fastest way to see what a payload
becomes.

---

## 7. Out of scope for this ticket

- **Transport.** The client consumes a local mock and has no socket. The
  WebSocket contract (URL, auth, reconnection, backpressure, heartbeat, ordering
  guarantees) is a separate ticket and needs a joint decision.
- Conversation persistence and history replay.
- Analytics on rendered payloads.
- Any provider-app support.
- Protocol v2 (remote images, capability negotiation, streamed partial UI).

---

## 8. Acceptance criteria

- [ ] Agent emits `message_start` / `text_delta` / `message_end` with a shared
      `messageId` and an authoritative final `text`.
- [ ] Agent emits at most one `ui` event per message, `schemaVersion` integer `1`.
- [ ] Only the 32 documented node types appear.
- [ ] Only the eleven implemented actions appear.
- [ ] Every `image.url` is https and points at an origin the mobile team knows
      about; every `image.assetId` is from the published catalog.
- [ ] Every semantic node carries a `fallbackText`.
- [ ] Prices, instants and distances are structured, not pre-formatted.
- [ ] Prose is localized in the user's language.
- [ ] Server-side validation rejects payloads breaching §4 before sending.
- [ ] All 12 fixtures render correctly in the mobile prototype.
- [ ] No Flutter code, Markdown-as-UI, or callbacks in any output.

---

## 9. Open questions for the mobile team

1. Which `assetId`s should be published for agent use beyond the five
   currently bundled illustrations?
2. Should `open_url` be enabled with a host allowlist, or stay out of v1?
3. Which entity ids does the agent have access to, and do they match what the
   app can open?
4. Which origins will serve AI-referenced images, so the client's image policy
   can be narrowed from "any https host" to an allowlist?

---

## 10. Gaps observed on `/user-agent/chat/stream`

Probed live against `agent-dev.trysanad.us` on 2026-09-04, when the client's
real transport moved from the WebSocket to this endpoint. **The framing and
envelope are correct** — `data: ` + one-line JSON, blank-line delimited, with
exactly `{eventId, conversationId, messageId, seq, type, createdAt, payload}`,
`seq` contiguous from 0, and `concat(text_delta.delta) == message_end.text` to
the character. Server-side conversation memory works: turn 2 on the same
`conversation_id` recalled turn 1.

Three gaps remain, all backend-side. The client is complete and waiting.

### 10.1 No `ui` events — blocks this entire ticket

Across every probe, including prompts explicitly asking for buttons and options,
the endpoint emitted only `message_start`, `text_delta` and `message_end`.
**Never `ui`.** The agent answers with Markdown numbered lists where §2 asks for
a `quick_reply` or `button` payload — exactly what §0.2 of
[`AI_CONTRACT.md`](AI_CONTRACT.md) forbids.

The OpenAPI spec makes this look structural rather than accidental:
`/user-agent/chat` is typed `UserChatResponse` = `{conversation_id, reply}`,
plain text. The `ChatResponse` schema that carries `{schemaVersion, blocks}`,
along with `TextNode`, `ButtonNode` and `QuickReplyNode`, is bound **only** to
the provider-facing `/agent` route.

**Ask:** emit protocol `ui` payloads from the user-agent, per §2 and §3. The
client's codec, validator, renderer and action registry are all wired and
tested for it today — no mobile change is needed when this lands.

### 10.2 The access token is accepted and ignored

`Sanad-Access-Token` is declared optional in the spec and there is no
`securitySchemes` block. An **invalid** token returns `200` and a full stream,
not `401`, and the agent then states it has no access to the user's profile or
bookings — it has no authenticated identity and no platform tools.

The client attaches the header correctly on every turn (and re-reads it each
turn, so a refresh is picked up). There is currently nothing behind it.

**Ask:** confirm whether the user-agent is meant to authenticate. If it is,
reject an invalid token rather than silently degrading, and give it the
user-scoped tools it needs.

### 10.3 Domain drift — is this the right assistant?

The user-agent self-identifies as *"Sanad Insurance"* and answers about
policies, claims, motor/travel/health cover. The SANAD client app is a services
and booking marketplace. The provider-facing `/agent`, by contrast, does talk
about services, branches and team.

**Ask:** product confirmation that the insurance-domain user-agent is the
intended assistant for the SANAD client app.

### 10.4 Smaller observations

| Observation | Impact |
|---|---|
| An empty `message` returns `200 text/event-stream` with a **completely empty body** — zero frames | Client handles it (no bubble opened, diagnostic only), but a `422` would be more honest |
| Errors are `422` + `application/json` **before** the stream, never an in-stream `error` frame | Client classifies by status only and never surfaces the Pydantic body |
| No keepalive/comment frames during generation | A stalled turn is indistinguishable from a dead connection until the 60s inter-chunk timeout |
| Worst measured time-to-first-token: **9.3s** | Drove the client's receive timeout up from the shared 15s default to 60s |
| `typing` events are never sent | Optional in the protocol; the client simply never shows the indicator |

---

## 11. Inbound attachments

New, and independent of §10: the client sends attachments on the turn. It ships
whether or not the backend reads them yet. Nothing below changes the outbound
envelope.

> **Changed since the first draft of this ticket — please re-read 11.2.**
> An earlier version of this section asked you to accept **recorded voice
> notes**: an audio attachment with `type: "audio"` and a device-produced
> `transcript`, plus a `message` mirror so a voice-only turn was understood
> before you read `attachments`. **That capability has been retired on the
> client.** AI Chat no longer records or uploads audio, and no build of the app
> will send you an audio attachment. Do not implement, and do not keep, a path
> that expects one.

### 11.1 Accept `attachments` on the turn

`POST /user-agent/chat/stream` (and the WS frame) receives:

```json
{
  "conversation_id": "conv_1",
  "message": "what does this say?",
  "attachments": [
    { "id": "68f1…", "url": "https://…" },
    { "id": "9ab2…", "url": "https://…" }
  ]
}
```

An attachment object is **exactly `id` and `url`** — no type discriminator and
no per-type extras.

The key is **absent** when the turn carries no files, so a text-only turn is the
same body you receive today and nothing needs to change for it.

Files are uploaded to `POST /api/v1/media/upload-single` (multipart, field
`file`) on the REST host before the turn is sent, and `id`/`url` are that
response's own fields.

**Asks**

- Parse `attachments`, and **ignore keys you do not recognise** — the client
  adds them additively.
- **Fetch by `url`. Do not resolve storage from `id`.** The whole point of
  sending both is that the location is already known; a lookup on your side is
  latency for nothing. `id` is for correlation, logging, and any later operation
  that genuinely needs the record.
- Reject nothing on the basis of the fields we *don't* send: file name, MIME
  type and size are deliberately absent, because you have the URL.

### 11.2 There is no audio attachment, and no transcript field

AI Chat supports **Speech-to-Text** as a voice input method. Speech is converted
to text on the client and submitted as a normal text message. Recorded audio is
not sent to the AI.

So a spoken turn reaches you as:

```json
{ "conversation_id": "conv_1", "message": "book me for tomorrow at nine" }
```

— indistinguishable from a typed one, which is exactly the intent. The user sees
the recognised words in the composer and can correct them before sending, so
what you receive is what they meant to say.

**Asks**

- **No server-side transcription work is required for this feature.** There is
  no audio arriving from AI Chat to transcribe.
- **Do not implement `type: "audio"` or `attachments[].transcript`.** If either
  is already built, it is dead code on this path; nothing will populate it.
- **`message` is the only place words appear**, typed or dictated. Treat one
  turn as one utterance.
- **An attachment-only turn has `message: ""`** — an image or document with no
  caption. §10.4 records that an empty `message` returns `200` with **zero
  frames**, so this is the case worth handling when you start reading
  `attachments`. It is the only remaining reason a turn can have no words.

### 11.3 Storage asks

- **Short-lived, signed URLs are preferred** over permanent public ones for
  private user files. `media/upload-single` currently returns a permanent URL.
  The client is written to tolerate either: the URL is minted at send and
  consumed in the same request, and nothing caches it or reuses it across
  turns. An expiry on the order of the request is sufficient.
- **Orphaned uploads need garbage collection on your side.** A batch that fails
  partway leaves earlier uploads stranded, and the client cannot clean them up:
  `DELETE /media/{id}` is provider-only. The client does not retry or
  compensate — it abandons the batch and tells the user.

### 11.4 What the client already does

No mobile work is pending on any of the above.

| | |
|---|---|
| Upload | `packages/media_upload` → `media/upload-single`, at send time, sequential, all-or-nothing |
| Voice input | `speech_to_text` on-device, tapped from the composer microphone; produces editable text, never a file |
| Recorded audio | **removed** — no recorder, no audio attachment, no audio serialization |
| Failure | one `error` bubble; the user's text stays in their own bubble |
| Supported types | images and `pdf/doc/docx/xls/xlsx/txt`; max 5 per message |

---

## 12. Interaction results — the contract the agent must implement

**Status: client-side complete and shipping. Server-side not started.**

The client now sends a structured result whenever the user answers a semantic
card. Nothing on the server has to change for the app to keep working — but
until it does, the agent is still recovering its own data by reading its own
prose.

### 12.1 What you receive

An additional, optional top-level key on the existing
`POST /user-agent/chat/stream` body (§11 covers `attachments`):

```json
{
  "conversation_id": "conv_1",
  "message": "Book me the 9:00 AM slot",
  "interaction": {
    "interactionId": "int_1757393641123456_9f2c1a...",
    "nodeId": "slots_1",
    "nodeType": "time_slots",
    "messageId": "msg_7",
    "kind": "slot_selected",
    "status": "submitted",
    "value": { "id": "s_0900", "label": "9:00 AM" },
    "text": "Book me the 9:00 AM slot",
    "createdAt": "2026-09-08T09:14:03.000Z"
  }
}
```

| Field | Presence | Meaning |
|---|---|---|
| `interactionId` | always | Client-minted idempotency key. Opaque. |
| `nodeId` | always | The `id` of the node the user answered. |
| `nodeType` | usually | The node type wire value. |
| `messageId` | chat only | The assistant message that carried the node. |
| `kind` | always | See 12.2. |
| `status` | always | `submitted` \| `cancelled` \| `failed` |
| `value` | always | Shape implied by `kind` — see 12.3. |
| `text` | usually | The sentence also in `message`. |
| `createdAt` | usually | UTC ISO-8601, client clock. |

**`interaction` is omitted entirely on an ordinary typed turn**, exactly as
`attachments` is omitted when there are no files. Its presence is the signal
that this turn is an *answer*.

### 12.2 Kinds

`quick_reply_selected`, `slot_selected`, `review_submitted`,
`location_selected`, `location_confirmed`, `permission_result`,
`media_result`.

### 12.3 Value shapes

| For | Fields |
|---|---|
| `slot_selected`, `quick_reply_selected` | `label` (required), `id` (when published) |
| `review_submitted` | `text` (required; **may be empty string**) |
| `location_selected`, `location_confirmed` | `name` (required), `source` (required: `saved` \| `typed`), `id`, `addressText` |
| `permission_result` | `permission` (required), `outcome` (required) |
| `media_result` | `count` (required), `source` |

`outcome` ∈ `granted`, `denied`, `permanently_denied`, `unavailable`,
`cancelled`. These are **protocol** values, not Android/iOS permission
statuses — the client maps its platform result onto them so no plugin
vocabulary reaches you.

### 12.4 What the agent must do

1. **Read `value`, not `text`.** `value.id` is the identifier *you* published
   in the node. Resolving a booking by matching a display label is what this
   whole section exists to stop.
2. **Branch on `status`.** `cancelled` means the user declined; acknowledge and
   offer a way forward. Never treat it as no answer and re-ask.
3. **Branch on `outcome` for `permission_result`.** `permanently_denied` means
   asking again cannot help. `unavailable` means the capability does not exist
   for this client — see 12.6.
4. **Treat `interactionId` as an idempotency key.** A retried turn carries the
   same id. Do not double-book.
5. **Use `messageId` to judge relevance.** The client does not expire cards, by
   design: a user can scroll back and answer a question from ten turns ago. You
   are the only party that knows whether that is still useful.
6. **Ignore unknown fields and unknown enum values.** Additive evolution, in
   both directions.
7. **Keep emitting templates.** `confirmTemplate` / `submitTemplate` are still
   required on the interactive nodes. They are the only source of the sentence
   a card posts, which is what stops a card posting words you did not author.

### 12.5 What breaks if you do nothing

Nothing. `message` still carries the sentence your template produced, so an
agent that ignores `interaction` receives exactly the body it receives today.
That is deliberate: this can be adopted whenever, with no client release to
coordinate against.

### 12.6 The location gap — read this one

`request_location_share` currently returns:

```json
{ "kind": "permission_result", "status": "cancelled",
  "value": { "permission": "location", "outcome": "unavailable" } }
```

**The client reads no device position.** The capability exists in the codebase
but only inside a package the chat app does not depend on, and pulling it in
would bring a Maps SDK, an API key and a DI bootstrap for a conversation
feature that does not otherwise need any of them.

So `unavailable` is a real, permanent answer for now, not a transient failure.
**Do not retry it.** Ask the user to name the place, or send a
`location_picker` — a chosen or typed place comes back as a proper
`location_selected` with `name`, `source` and, for a saved place, the `id` you
published.

When a device-location capability is added, the result gains coordinates
additively; the shape above does not change.

### 12.7 Live voice — not in this ticket

The client can render a semantic card mid-session and return an interaction
result over the session's own channel, using the same objects described above.
**There is no realtime voice backend to talk to.** The semantic beats are
currently supplied by a local script and the assistant's audio is the user's
own capture played back.

When a realtime transport is specified, its requirements are:

- a server→client frame carrying a `{schemaVersion, blocks}` payload,
  identical to the chat `ui` event's;
- a client→server frame carrying the `interaction` object above, minus
  `messageId` (a session has no assistant messages — `nodeId` correlates);
- the server must expect the session to fall silent between sending a card and
  receiving its answer. The client releases the microphone for that window, so
  no audio and no transcript arrive during it — this is not a dropped
  connection.

### 12.8 Acceptance

- [ ] The agent parses `interaction` and resolves entities by `value.id`.
- [ ] `status: "cancelled"` produces an acknowledgement, never a re-ask.
- [ ] Each `permission_result.outcome` produces a distinct continuation.
- [ ] `outcome: "unavailable"` for location is never retried.
- [ ] `interactionId` deduplicates a retried turn.
- [ ] An empty `review_submitted.text` is accepted as an answer.
- [ ] Turns with no `interaction` behave exactly as before.

---

## 13. The agent's memory record is being emitted on the text channel

**Severity: P0 — this is a user-visible data leak, not a rendering nit.**

### 13.1 What was observed

Captured off the live socket on 2026-09-09 (client build `development`,
`conv_1788967635676795`, `msg_15ae2f90aef0482abe7c88ec9bdfc8d4`). Whenever the
agent recalls stored memory, the **first `text_delta` of the answer is not
prose**. `payload.delta` at `seq: 1` is the raw memory-store result, as one
self-contained JSON array:

```json
[{"namespace":["memories","4f455c1a-9e0b-47b4-a88b-eb5eef68b586"],
  "key":"4036579c-d857-4a84-b844-ed78e315cdf5",
  "value":{"kind":"Memory","content":{"content":"المستخدم مهتم بخدمات حكومة الإمارات … عند مساعدته: وجّهه إلى القنوات الرسمية …"}},
  "created_at":"2026-09-09T12:58:20.531632+00:00",
  "updated_at":"2026-09-09T13:00:54.261163+00:00",
  "score":0.4937393955873758}]
```

The real answer then streams normally from `seq: 2` onward (`Based`, ` on`,
` my`, ` memory`, …).

**The same blob is also prefixed onto `message_end.payload.text`.** Because
`message_end.text` is authoritative for the finished bubble, this is not a
transient streaming artefact — it survives into the completed message.

### 13.2 Why this is P0

Rendered to the user, that single frame exposes:

- internal `namespace` and `key` UUIDs of the memory store,
- a relevance `score`,
- a paraphrase of the user's **own earlier conversation**,
- the agent's **private instructions to itself** ("عند مساعدته: وجّهه إلى …").

None of it is an answer. To a user it reads as the app leaking their data. It
also tore the answer's first word in half on screen ("He" … envelope …
"re's a guide"), because the envelope landed between two prose deltas.

### 13.3 What the backend must change

1. **Never emit memory-store results on the `text_delta` channel.** Memory
   recall is not assistant prose and must not share a channel with it.
2. **Never prefix it onto `message_end.payload.text`.** That field is the
   authoritative rendered message.
3. If the memory record is genuinely useful to a client (today it is not),
   send it as its own event `type` — the codec already ignores unknown types
   forward-compatibly, so introducing one breaks no released client.

### 13.4 The client does nothing about this

**There is no client-side mitigation, by deliberate decision.** The chat client
passes `text_delta` and `message_end.text` through exactly as received: it does
not inspect, classify, strip, rewrite or suppress streamed text based on what it
looks like.

A narrow structural guard was briefly present in the codec and has been removed
on purpose. Filtering here would be keyed to one observed payload shape, would
silently drift the moment the memory record changed, and would hide a backend
defect behind client code that nobody would then be motivated to remove.

**So this leak is live and user-visible until 13.3 ships.** Anything on the text
channel reaches the user's screen.

### 13.5 Acceptance

- [ ] No `text_delta` payload ever parses as a memory record.
- [ ] `message_end.payload.text` contains only the assistant's answer.
- [ ] A conversation with recalled memory renders identically to one without.
