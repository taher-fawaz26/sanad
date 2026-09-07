# SANAD Chat UI Protocol — v1 (normative)

`schemaVersion: 1`

This document describes the protocol **as implemented** in
[`packages/ai_ui_protocol`](../../packages/ai_ui_protocol). Every field, enum
value and limit below is enforced by `AiUiValidator` and covered by tests. If
this document and the code disagree, the code is right and this document is a
bug.

Audience: anyone reading or changing the client. The agent-facing rules live in
[`AI_CONTRACT.md`](AI_CONTRACT.md), which is a strict subset of this.

---

## 1. Event envelope

Transport-agnostic. Nothing in the model knows whether a frame arrived over a
WebSocket, SSE, or the local mock.

```json
{
  "eventId": "evt_01J8X...",
  "conversationId": "conv_123",
  "messageId": "msg_456",
  "seq": 3,
  "type": "ui",
  "createdAt": "2026-08-31T09:00:00Z",
  "payload": { }
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `eventId` | string | **yes** | Non-empty. A frame without one is ignored. |
| `type` | string | **yes** | One of the six below. Anything else is ignored. |
| `messageId` | string | conditional | Required for `message_start`, `text_delta`, `message_end`, `ui`. Optional for `typing`, `error`. |
| `conversationId` | string | no | Carried through, not interpreted by v1. |
| `seq` | integer | no | Defaults to `0`. A non-integer also yields `0`. |
| `createdAt` | ISO-8601 | no | Normalised to UTC. Unparseable → `null`. |
| `payload` | object | per type | Missing/non-object → treated as `{}`. |

### Event types

| `type` | `payload` | Client behaviour |
|---|---|---|
| `message_start` | `{"role": "assistant"}` | Opens an empty assistant bubble. `role` defaults to `"assistant"`. |
| `text_delta` | `{"delta": "I found "}` | Appends to the active message. **Emits no chat state.** A non-string `delta` makes the frame ignored. |
| `message_end` | `{"text": "…"}` | Closes the message. `text` is **authoritative** and replaces accumulated deltas. Absent `text` → the accumulated deltas stand. |
| `ui` | `{"schemaVersion": 1, "blocks": [...]}` | Validated once and attached to `messageId`. Empty payload → frame ignored. |
| `typing` | `{"active": true}` | Toggles the typing indicator. Anything other than `true` is `false`. |
| `error` | `{"code": "...", "message": "..."}` | Marks the active message failed. `code` defaults to `"unknown"`. `message` is agent-localized prose. |

Reserved and **not implemented**: `tool_status`. Unknown types are ignored with
a diagnostic, never treated as an error — a backend can ship a new event kind
before clients understand it.

Decoded by `AiChatEventCodec`, which is total: a truncated frame, non-JSON, a
non-object root, or an oversized frame all return `AiChatEventIgnored`.

---

## 2. UI payload

```json
{ "schemaVersion": 1, "blocks": [ <node>, … ] }
```

`blocks` is an ordered vertical sequence rendered inside one assistant bubble.
Modelling the root as a list rather than a single node is what makes "prose +
card + buttons in one reply" natural with no wrapper node.

- `schemaVersion` must be the **integer** `1`. `"1"`, `0`, `2` and a missing
  value all reject the whole payload.
- `blocks` must be an array. Anything else rejects the whole payload.
- An empty `blocks` array parses successfully but is not renderable.
- More than 12 blocks: truncated to the first 12, diagnostic emitted.

---

## 3. Node shape

Every node accepts these four fields:

| Field | Type | Required | Notes |
|---|---|---|---|
| `type` | string | **yes** | Missing, non-string or empty → node dropped. |
| `id` | string | no | Defaults to the node's document path, e.g. `blocks[0].children[2]`. Used as the widget key. |
| `a11yLabel` | string | no | Screen-reader label. On leaf nodes it **replaces** the derived label; on containers it labels the group and children stay reachable. |
| `fallbackText` | string | no | Rendered as plain text by a client that does not recognise `type`. |

Reserved keys — present in the schema, **rejected in v1** with a
`reserved_property` diagnostic: `textKey`, `textArgs`.

Any other unrecognised key is ignored with an `invalid_property` diagnostic.
Unknown keys are never fatal.

---

## 4. Primitive nodes (15)

Defaults shown are what the client applies when the field is absent **or**
holds an unrecognised enum value (the latter also emits `invalid_property`).

### 4.0 Enum vocabularies

Every style field is a closed set of exact strings. There is no way to express a
colour, a pixel value, a font, or a `left`/`right` direction.

| Enum | Values | Used by |
|---|---|---|
| text style | `title`, `body`, `caption`, `label` | `text.style` |
| emphasis | `normal`, `strong`, `muted` | `text.emphasis`, `rich_text` spans |
| main-axis align | `start`, `center`, `end`, `spaceBetween` | `text.align`, `rich_text.align`, `row.align` |
| cross-axis align | `start`, `center`, `end` | `row.crossAlign`, `column.align` |
| tone | `neutral`, `primary`, `info`, `success`, `warning`, `error` | `icon.tone`, `card.tone`, `chip.tone`, `badge.tone`, `statusTone` |
| spacing step | `xs`, `sm`, `md`, `lg`, `xl` | `divider.spacing`, `spacer.size`, `row.gap`, `column.gap` |
| icon size | `sm`, `md`, `lg` | `icon.size` |
| image aspect | `square`, `wide`, `thumb` | `image.aspect` |
| image fit | `cover`, `contain` | `image.fit` |
| button variant | `primary`, `secondary`, `outline`, `transparent` | `button.variant` |
| button intent | `standard`, `warning`, `destructive`, `neutral` | `button.intent` |
| button size | `block`, `large`, `small` | `button.size` |
| list variant | `plain`, `sectioned` | `list.variant` |
| text direction | `auto`, `ltrValue` | `text.direction` |

`start` and `end` are **visual**: they resolve against the ambient text
direction and mirror automatically under Arabic.

### `text`
| Field | Type | Req | Default / limits |
|---|---|---|---|
| `text` | string | **yes** | ≤ 2000 chars; longer is truncated. Blank → node dropped. |
| `style` | enum | no | `body`. One of `title`, `body`, `caption`, `label`. |
| `emphasis` | enum | no | `normal`. One of `normal`, `strong`, `muted`. |
| `align` | enum | no | `start`. One of `start`, `center`, `end`, `spaceBetween`. |
| `direction` | enum | no | `auto`. One of `auto`, `ltrValue`. |
| `maxLines` | integer | no | 1–20, clamped. Absent → unlimited. |

`direction: "ltrValue"` wraps the string in Unicode bidi isolates so an
inherently-LTR value (phone number, email, reference id) renders correctly under
Arabic.

**Markdown in prose.** `text` may contain a bounded Markdown subset and the
client renders it: `#`/`##`/`###` headings, `-`/`*`/`+` bullets, `1.` ordered
lists, `**bold**`, `__bold__`, `*italic*`, `_italic_`, `` `code` ``, and blank-line
paragraph breaks. Anything else is shown literally.

Link and image syntax is **not** rendered: `[label](url)` and `![alt](url)`
collapse to their visible label and the URL is discarded. Nothing produced from
a `text` node is ever tappable. Markdown is a prose convenience, never a UI
transport — buttons, cards and actions must be structured nodes.

`direction: "ltrValue"` disables Markdown parsing for that node: a reference id
is a value, not prose, and its punctuation must survive verbatim.

### `rich_text`
| Field | Type | Req | Default / limits |
|---|---|---|---|
| `spans` | array | **yes** | 1–20 spans; excess truncated. Empty/absent → node dropped. |
| `align` | enum | no | `start`. |

Each span: `{"text": string (required, ≤2000), "emphasis": enum (default
`normal`), "action": action object (optional)}`. A span with an unresolvable
action renders as plain text. If no span survives, the node is dropped.

### `icon`
| Field | Type | Req | Default / limits |
|---|---|---|---|
| `name` | string | **yes** | ≤ 120 chars. A SANAD icon token or a Font Awesome CSS class (`"fa-solid fa-store"`). Unresolvable → node renders nothing. |
| `size` | enum | no | `md`. One of `sm`, `md`, `lg`. |
| `tone` | enum | no | `neutral`. |

### `image`
| Field | Type | Req | Default / limits |
|---|---|---|---|
| `alt` | string | **yes** | ≤ 64 chars. Absent → node dropped. |
| `assetId` | string | **yes** | Must be an id the host publishes; otherwise node dropped. |
| `url` | — | **rejected** | See below. |
| `aspect` | enum | no | `wide`. One of `square`, `wide`, `thumb`. |
| `fit` | enum | no | `cover`. One of `cover`, `contain`. |

> **v1 is `assetId`-only.** A `url` on an image node is rejected outright with a
> `reserved_property` diagnostic — this is *not* a host check, and the app's own
> CDN is refused too. An agent-supplied image URL is a network and tracking
> surface v1 does not need: semantic cards carry an entity id, so the app
> fetches real artwork itself. When both `assetId` and `url` are present, the
> `assetId` is used and the `url` is flagged.
>
> `AiUiRemoteImage` and `AiUiUrlPolicy` exist in the codebase as future-ready
> infrastructure. No v1 payload can produce an `AiUiRemoteImage`.

### `divider`
`spacing`: enum, default `md`, one of `xs`, `sm`, `md`, `lg`, `xl`.

### `spacer`
`size`: enum, default `md`, same set.

### `row`
| Field | Type | Req | Default / limits |
|---|---|---|---|
| `children` | array | **yes** in practice | 1–8; excess truncated. A row left with no children is dropped. |
| `align` | enum | no | `start`. `start`/`end` are **directional** — they flip under RTL. |
| `crossAlign` | enum | no | `center`. One of `start`, `center`, `end`. |
| `gap` | enum | no | `sm`. |
| `wrap` | boolean | no | `false`. |

### `column`
`children` 1–12 (dropped if empty), `align` (cross-axis) default `start`,
`gap` default `sm`.

### `card`
| Field | Type | Req | Default / limits |
|---|---|---|---|
| `children` | array | no | 0–12. A card with a `title` survives having none. |
| `title` | string | no | ≤ 64. |
| `tone` | enum | no | `neutral`. |
| `action` | action | no | Whole-card tap; announced as a single button. |

### `button`
| Field | Type | Req | Default / limits |
|---|---|---|---|
| `label` | string | **yes** | ≤ 64. |
| `action` | action | **yes** | Unresolvable → **the whole button is dropped**. |
| `variant` | enum | no | `primary`. One of `primary`, `secondary`, `outline`, `transparent`. |
| `intent` | enum | no | `standard`. One of `standard`, `warning`, `destructive`, `neutral`. |
| `size` | enum | no | `block`. One of `block`, `large`, `small`. |
| `icon` | string | no | ≤ 120, same resolution as `icon.name`. |
| `enabled` | boolean | no | `true`. `false` renders a genuinely disabled control. |

### `chip`
`label` required (≤ 40). `action` optional — unlike a button, an unresolvable
action **downgrades** the chip to a static label rather than dropping it.
`selected` default `false`, `tone` default `neutral`, `icon` optional.

### `list`
`children` must be `list_item` nodes, 1–20 (excess truncated, non-`list_item`
children dropped with a diagnostic). A list with no valid items is dropped.
`variant` default `plain` (`plain` | `sectioned`), `emptyText` optional (≤ 64).

Rendered as a bounded column — **never a nested scrollable**.

### `list_item`
| Field | Type | Req | Limits |
|---|---|---|---|
| `title` | string | **yes** | ≤ 64 |
| `subtitle` | string | no | ≤ 2000 |
| `leadingIcon` | string | no | ≤ 120 |
| `leadingImage` | object | no | `{"assetId": "..."}` — same assetId-only rule |
| `badge` | object | no | `{"label": ≤40, "tone": enum default neutral}` |
| `trailingText` | string | no | ≤ 64 |
| `action` | action | no | |

### `progress`
`value` number 0–1 (clamped), optional — absent means indeterminate and renders
an activity indicator instead of a bar. `label` optional (≤ 64).

### `loading`
`label` optional (≤ 64).

---

## 5. Semantic nodes (5)

These are the **only** semantic components in v1. All are client-domain. There
are no provider-domain semantic components.

Structured values are sent structured and formatted by the client in the
device's locale — the agent never formats a currency, an instant, or a distance.

### `service_card`
| Field | Type | Req | Limits |
|---|---|---|---|
| `serviceId` | string | **yes** | |
| `title` | string | **yes** | ≤ 64 |
| `subtitle` | string | no | ≤ 2000 |
| `price` | object | no | `{"amount": number, "currency": 3-letter ISO-4217}`. Malformed → price dropped, card kept. |
| `ratingValue` | number | no | 0–5, clamped |
| `image` | object | no | `{"assetId": "..."}` |
| `badge` | object | no | `{"label", "tone"}` |
| `action` | action | no | |

### `appointment_card`
`appointmentId` **required**, `title` **required** (≤ 64), `startsAt`
**required** — ISO-8601, normalised to UTC; unparseable drops the node.
Optional: `whereText` (≤ 2000), `status` (≤ 40), `statusTone` (default
`neutral`), `action`.

### `branch_card`
`branchId` **required**, `name` **required** (≤ 64). Optional: `addressText`
(≤ 2000), `distanceMeters` (number, 0–40 000 000), `status` (≤ 40),
`statusTone` (default `neutral`), `action`.

### `document_card`
`documentId` **required**, `title` **required** (≤ 64), `status` **required**
(≤ 40). Optional: `statusTone` (default `neutral`), `action`.

### `quick_reply`
`options` **required**: 2–6 entries of `{"label": ≤40, "action": action}`.
Excess truncated; fewer than 2 *valid* options drops the node.

---

## 6. Actions

```json
{ "type": "open_service", "serviceId": "svc_123" }
```

Eleven action types are defined by the protocol:

| `type` | Required params |
|---|---|
| `send_message` | `text` |
| `open_service` | `serviceId` |
| `open_appointment` | `appointmentId` |
| `open_branch` | `branchId` |
| `open_document` | `documentId` |
| `open_route` | `routeKey` — a **symbolic key**, never a path |
| `open_url` | `url` — gated by `AiUiUrlPolicy` (https + host allowlist) |
| `copy_text` | `text` |
| `request_location_share` | — — asks the app to run its own location flow |
| `request_image_upload` | — — asks the app to run its own picker/upload flow |
| `dismiss` | — |

The two `request_*` actions grant the agent **no** device access. They state an
intent; the app owns the permission prompt, the picker and the decision to
refuse. Emitting one is a request, never a capability.

Additional scalar params (string, number, bool) are carried through as strings.
Non-scalar params are dropped with a diagnostic. `open_route` additionally
accepts a nested `"params"` object of scalars.

**Two independent gates.** An action must be in the protocol catalog *and* in
the host's `supportedActions` set. The SANAD client implements eight:
`send_message`, `open_service`, `open_appointment`, `open_branch`,
`open_document`, `copy_text`, `request_location_share`, `request_image_upload`.
`open_url` and `open_route` are **not implemented** — a payload using either is
dropped.

Not representable in any form: a callback, a method name, a Dart expression, a
raw route path, a raw deep link.

---

## 7. Limits

| Limit | Value | Behaviour when exceeded |
|---|---|---|
| Payload size (UTF-8 bytes) | 32 768 | Whole payload rejected |
| Nodes per message | 100 | Whole payload rejected |
| Nesting depth (`blocks` = 1) | 6 | Offending subtree dropped |
| `blocks` | 12 | Truncated |
| `column` / `card` children | 12 | Truncated |
| `row` children | 8 | Truncated |
| `list` children | 20 | Truncated |
| `rich_text` spans | 20 | Truncated |
| `quick_reply` options | 2–6 | Truncated / node dropped |
| `text.text`, `list_item.subtitle` | 2000 | Truncated |
| Labels, titles, `alt` | 64 | Truncated |
| Chip/badge/status labels | 40 | Truncated |
| Actions per message | 12 | Further actions unresolvable |
| Images per message | 4 | Further images dropped |
| `maxLines` | 1–20 | Clamped |

Size and node-count overruns reject the whole payload; child/depth overruns
truncate and keep going. One greedy list should not blank an entire reply.

---

## 8. Validation pipeline and failure behaviour

```text
raw string
  → AiUiCodec.decode        size guard, JSON decode      — never throws
  → AiUiValidator.validate  version, catalog, props, actions, limits
  → AiUiParseResult         AiUiDocument? + List<AiUiDiagnostic>
```

Both stages are **total**: there is no input for which either throws.

| Situation | Behaviour | Diagnostic |
|---|---|---|
| Malformed JSON / non-object root | Whole payload rejected | `malformed_payload` |
| `schemaVersion` missing, non-int, or ≠ 1 | Whole payload rejected | `unsupported_schema_version` |
| `blocks` missing or not an array | Whole payload rejected | `malformed_payload` |
| Unknown node `type` **with** `fallbackText` | Rendered as a `text` node | `unknown_node_type` |
| Unknown node `type` without it | Dropped (release) / labelled marker (dev builds) | `unknown_node_type` |
| Unknown property | Ignored | `invalid_property` |
| Reserved property (`textKey`, `textArgs`, `image.url`) | Ignored / node dropped | `reserved_property` |
| Missing required property | Node dropped, siblings kept | `missing_required_property` |
| Wrong property type | Node dropped or field ignored | `invalid_property` |
| Unknown enum value | Documented default applied | `invalid_property` |
| Unknown/unimplemented action | Owning button dropped; chip downgraded | `unknown_action_type` |
| `open_url` failing the URL policy | Action dropped | `blocked_url` |
| Unpublished `assetId` | Node dropped | `unknown_asset_id` |
| Any limit exceeded | Truncate or reject per §7 | `limit_exceeded` |
| A renderer throws | That subtree renders nothing | `renderer_failure` |

The primary defence is *parse, don't validate-at-render*: renderers are total
functions over an already-validated tree, so nothing is left to be invalid at
build time.

**Diagnostics are privacy-safe.** `AiUiDiagnostic.detail` carries field names,
type names, limit numbers and enum names — never user or AI prose — and is
capped at 120 characters.

---

## 9. Versioning

- `schemaVersion` is an integer. The client supports exactly `{1}`.
- **Additive changes do not bump it**: new node types, new action types, new
  optional properties. Older clients degrade through `fallbackText`.
- The version moves only when the meaning of an existing node changes.
- There is **no capability negotiation** in v1. `fallbackText` is the entire
  forward-compatibility strategy.

---

## 10. Localization and direction

- The agent sends **final localized prose**. The client renders it verbatim and
  never calls `.tr()` on payload text.
- Client-owned chrome uses the `ai_chat.*` namespace in both `en-US.json` and
  `ar-AR.json`.
- **RTL is the default** (both apps start `ar-AR`). `start`/`end` are visual and
  flip automatically; the protocol has no `left`/`right`.
- Structured values (`price`, `startsAt`, `distanceMeters`, `ratingValue`) are
  formatted client-side in the device locale, using the repo's 12-hour
  `DateFormat('h:mm a')` convention.

---

## 11. Accessibility

- Every node maps to a real semantic widget; nothing renders as a bare
  `GestureDetector`.
- `image.alt` is **required** — an image the agent could not describe is dropped
  rather than rendered inaccessibly.
- `a11yLabel` overrides the derived label on leaf nodes and labels the group on
  containers.
- A card with a whole-card action is one `Semantics(button: true)` node, so a
  screen reader announces one destination.
- `progress` and `loading` are live regions.

## 12. The outgoing turn (client → agent)

Normative. `AiChatTurnPayload.encode` is the only thing that builds this, and
`ai_chat_turn_payload_test.dart` pins every rule below.

```
{
  "conversation_id": String,   // always
  "message":         String,   // always; may be ""
  "attachments":     [         // only when the turn carries files
    {
      "id":         String,    // always — the upload id
      "url":        String,    // always — the resolved location
      "type":       "audio",   // audio attachments only
      "transcript": String     // audio only, and only when non-empty
    }
  ]
}
```

### Rules

1. **`attachments` is omitted when empty**, never sent as `[]`. This is what
   makes a text-only turn byte-identical to the two-field body of protocol
   v1.0, so this addition is not a protocol bump and the existing
   request-shape tests hold unchanged. Do not "tidy" it into always emitting
   the key.
2. **A non-audio attachment object has exactly `id` and `url`.** Nothing else
   is sent — no file name, MIME type, size, local path, duration or waveform.
   The URL is already resolved, so the agent performs no storage lookup, and no
   device path ever leaves the phone.
3. **An audio attachment adds `type: "audio"`**, whether or not it has words —
   so the agent can tell speech it has no transcript for from an opaque file.
4. **`transcript` is present only when non-empty.** It is client-side device
   STT captured during the recording, and is best-effort: empty is the normal
   outcome when the recogniser was unavailable or heard nothing.
5. **`message` is never empty when the turn has something to say.** With no
   typed caption and a transcript available, `message` takes the transcript.
   Not decoration — the live agent answers an empty `message` with `200` and
   zero frames (see `ARCHITECTURE.md` §3), so a voice-only turn would otherwise
   be met with silence. It also means a voice note is understood by a backend
   that has not yet learned to read `attachments`.
6. **`message` is passed through verbatim, untrimmed.** Trimming happens once,
   in `AiChatBloc`; doing it again here would silently change a pinned body.
7. **Nothing credential-shaped is ever in the body.** The session token is a
   header (`Sanad-Access-Token`) on both transports.

### Why the transcript is on the attachment

`message` already belongs to what the user *typed*, and a turn can carry both a
caption and a voice note. A top-level `transcript` would either collide with the
caption or need a rule about which wins. On the attachment, the words stay
attached to the audio they came from, and a turn with two recordings would still
be unambiguous.
