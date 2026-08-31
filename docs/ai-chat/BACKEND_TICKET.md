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

### 3.2 Prefer the five semantic components
`service_card`, `appointment_card`, `branch_card`, `document_card`,
`quick_reply`. Do **not** rebuild any of them from `row`/`column`/`text`.

Each carries the real entity id (`serviceId`, `appointmentId`, `branchId`,
`documentId`). **Action required:** confirm with the mobile team that the ids
the agent has are the ids the app can open.

These five are the complete semantic set. No provider-domain components exist.

### 3.3 Images are `assetId`-only
There are **no remote images in v1**. `image.url` is rejected for every host,
including SANAD's own CDN.

**Action required:** agree the published `assetId` list with the mobile team. It
is currently a short list of bundled illustrations. To show real service or
branch artwork, emit the semantic card — the app fetches the image itself from
the entity id.

### 3.4 Only six actions are implemented
`send_message`, `open_service`, `open_appointment`, `open_branch`,
`open_document`, `copy_text`.

`open_url` and `open_route` are defined in the protocol but **no client
implements them**. A button using either is dropped entirely. Do not emit them.

### 3.5 Structured values, localized prose
Send `price` as `{"amount": 100, "currency": "AED"}`, `startsAt` as ISO-8601
UTC, `distanceMeters` as a number in metres. The client formats all three for
the reader's language, currency conventions and clock.

Send `title`, `subtitle`, `text` **already localized** in the user's language.
The app does not translate payload text. Arabic is the default.

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
- every `type` is one of the 20 documented node types
- every action `type` is one of the six implemented
- required fields present: `text`, `label`, `alt`, `title`, entity ids,
  `startsAt`, `quick_reply.options ≥ 2`
- no `image.url` anywhere
- limits: **32 KB** payload, **100** nodes, depth **6**, 12 blocks, 12
  column/card children, 8 row children, 20 list children, 20 spans, 12 actions,
  4 images, text ≤ 2000, labels ≤ 64, chip/badge/status labels ≤ 40

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
| `image.url` | drops the image, issues no request |
| Unknown `assetId` | drops the image |
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
8. a node type the client does not know, **with** `fallbackText`
9. an unsupported action
10. a deliberately malformed payload
11. a payload exceeding size/depth/child limits
12. a long streaming reply (60+ deltas) plus a `ui` event

The mobile prototype already ships equivalents in
`apps/sanad_client/lib/src/features/ai_chat/src/data/mock_scenarios.dart` —
match those shapes so both sides test the same things.

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
- [ ] Only the 20 documented node types appear.
- [ ] Only the six implemented actions appear.
- [ ] No `image.url` in any payload; every image uses an agreed `assetId`.
- [ ] Every semantic node carries a `fallbackText`.
- [ ] Prices, instants and distances are structured, not pre-formatted.
- [ ] Prose is localized in the user's language.
- [ ] Server-side validation rejects payloads breaching §4 before sending.
- [ ] All 12 fixtures render correctly in the mobile prototype.
- [ ] No Flutter code, Markdown-as-UI, or callbacks in any output.

---

## 9. Open questions for the mobile team

1. Which `assetId`s should be published for agent use beyond the current
   bundled illustrations?
2. Should `open_url` be enabled with a host allowlist, or stay out of v1?
3. Which entity ids does the agent have access to, and do they match what the
   app can open?
4. Do we want remote images in v2, and behind which allowlist?
