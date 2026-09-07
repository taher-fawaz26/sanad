# SANAD Chat UI Protocol — Agent Contract v1

**Audience:** whoever builds the SANAD AI agent. This is the complete set of
rules for producing UI the SANAD mobile app will render. You need no Flutter
knowledge to implement it.

**Status:** frozen. The client implements exactly this and nothing more. The
normative client-side reference is [`PROTOCOL_V1.md`](PROTOCOL_V1.md); this
document is the agent-facing subset plus the rules about *when* to use what.

---

## 0. The three absolute prohibitions

1. **Never emit Flutter or Dart code.** Not `Row(...)`, not `Container(...)`,
   not a widget name, not a code block containing either. The app has no
   interpreter; such output is discarded.
2. **Never use Markdown to describe UI.** Markdown *prose* inside a `text`
   node is fine and is rendered (bold, italic, inline code, headings, bullet
   and numbered lists). What is forbidden is Markdown standing in for
   structure: no `|` tables, no `[text](url)` link pretending to be a button,
   no `![alt](url)` image. Link and image syntax is stripped to its label and
   is never tappable. Anything interactive must be a structured node with an
   action from §5.
3. **Never emit executable intent.** No `onTap`, no `callback`, no function
   name, no expression, no raw route path, no deep link. Actions are declarative
   objects from a fixed catalog (§5).

---

## 1. Message envelope

Each assistant turn is a sequence of events:

```json
{"eventId": "evt_1", "conversationId": "conv_9", "messageId": "msg_7", "seq": 0, "type": "message_start", "payload": {"role": "assistant"}}
{"eventId": "evt_2", "conversationId": "conv_9", "messageId": "msg_7", "seq": 1, "type": "text_delta",    "payload": {"delta": "I found "}}
{"eventId": "evt_3", "conversationId": "conv_9", "messageId": "msg_7", "seq": 2, "type": "text_delta",    "payload": {"delta": "3 services."}}
{"eventId": "evt_4", "conversationId": "conv_9", "messageId": "msg_7", "seq": 3, "type": "ui",            "payload": {"schemaVersion": 1, "blocks": [ ... ]}}
{"eventId": "evt_5", "conversationId": "conv_9", "messageId": "msg_7", "seq": 4, "type": "message_end",   "payload": {"text": "I found 3 services."}}
```

Rules:

- `eventId` is required and must be non-empty. A frame without one is dropped.
- `messageId` is **required** for `message_start`, `text_delta`, `message_end`
  and `ui`. All events for one assistant turn share the same `messageId`.
- `seq` is an integer, monotonic per conversation. Absent or non-integer → `0`.
- `createdAt`, if sent, must be ISO-8601.
- `message_end.text` is **authoritative**: send the complete final text, not the
  last fragment. It replaces whatever the deltas accumulated, so a dropped
  delta cannot leave a permanently wrong bubble.
- `typing` (`{"active": true|false}`) and `error`
  (`{"code": "...", "message": "..."}`) may be sent at any point.
- A `ui` event may arrive before or after `message_end`; both work. One `ui`
  event per message.

Do **not** send `tool_status` — it is reserved and currently ignored.

---

## 2. UI payload

```json
{ "schemaVersion": 1, "blocks": [ <node>, ... ] }
```

- `schemaVersion` must be the JSON **integer** `1`. `"1"` (a string) rejects the
  entire payload. This is the single most likely mistake — check it first.
- `blocks` is an array, rendered top to bottom inside one chat bubble.
- Maximum 12 blocks. Extra blocks are silently dropped.

---

## 3. Every node

```json
{ "type": "text", "id": "n1", "a11yLabel": "...", "fallbackText": "...", ... }
```

| Field | Required | Notes |
|---|---|---|
| `type` | **yes** | Must be one of the 20 types in §4 and §6. |
| `id` | no | Recommended. Stable string, unique within the payload. |
| `a11yLabel` | no | Screen-reader label. Use it when the visible text reads badly aloud (e.g. a phone number). |
| `fallbackText` | no | **Required in practice on every semantic node.** See §7. |

Unknown fields are ignored. `textKey` and `textArgs` are reserved and rejected.

---

## 4. Primitive components (15)

Enum values are exact strings. An unrecognised enum falls back to the default.

### `text`
```json
{"type": "text", "id": "t1", "text": "Your appointment is confirmed", "style": "body", "emphasis": "normal", "align": "start", "direction": "auto", "maxLines": 3}
```
- `text` **required**, ≤ 2000 chars.
- `style`: `title` | `body` | `caption` | `label` — default `body`
- `emphasis`: `normal` | `strong` | `muted` — default `normal`
- `align`: `start` | `center` | `end` | `spaceBetween` — default `start`
- `direction`: `auto` | `ltrValue` — default `auto`. Use `ltrValue` for phone
  numbers, emails, URLs shown as text, IBANs and reference ids, so they render
  correctly in Arabic.
- `maxLines`: integer 1–20.

### `rich_text`
```json
{"type": "rich_text", "id": "r1", "spans": [
  {"text": "Booking "},
  {"text": "confirmed", "emphasis": "strong"},
  {"text": " — tap for details.", "emphasis": "muted"}
]}
```
- `spans` **required**, 1–20. Each span: `text` (required), `emphasis`
  (optional), `action` (optional — makes the span a link).
- Use this when a span needs an **action** (an inline link). For plain
  emphasis, Markdown inside a `text` node is simpler and equally supported.

### `icon`
```json
{"type": "icon", "id": "i1", "name": "fa-solid fa-calendar", "size": "md", "tone": "neutral"}
```
- `name` **required**, ≤ 120. A Font Awesome CSS class string. If the app cannot
  resolve it, the icon renders nothing — never rely on an icon to carry meaning.
- `size`: `sm` | `md` | `lg` — default `md`
- `tone`: `neutral` | `primary` | `info` | `success` | `warning` | `error` — default `neutral`

### `image`
```json
{"type": "image", "id": "im1", "assetId": "service_tools", "alt": "Service tools", "aspect": "wide", "fit": "cover"}
```
- `assetId` **required** — one of the ids the app publishes. Ask the mobile team
  for the current list; an unknown id drops the node.
- `alt` **required**, ≤ 64. A node without it is dropped.
- `aspect`: `square` | `wide` | `thumb` — default `wide`
- `fit`: `cover` | `contain` — default `cover`

> **Do not send a `url`.** v1 has no remote images. A `url` is rejected for
> every host, including SANAD's own CDN. To show a real service or branch photo,
> use the matching semantic card (§6) — the app fetches the artwork itself from
> the entity id.

### `divider` / `spacer`
```json
{"type": "divider", "id": "d1", "spacing": "md"}
{"type": "spacer",  "id": "s1", "size": "lg"}
```
`spacing`/`size`: `xs` | `sm` | `md` | `lg` | `xl` — default `md`.

### `row`
```json
{"type": "row", "id": "r1", "align": "start", "crossAlign": "center", "gap": "sm", "wrap": false, "children": [ ... ]}
```
- 1–8 children. `align`: `start` | `center` | `end` | `spaceBetween`.
  `crossAlign`: `start` | `center` | `end`. `gap`: spacing step. `wrap`: boolean.
- `start`/`end` are **visual**, and flip automatically in Arabic. There is no
  `left`/`right`.

### `column`
```json
{"type": "column", "id": "c1", "align": "start", "gap": "sm", "children": [ ... ]}
```
1–12 children. `align` is horizontal: `start` | `center` | `end`.

### `card`
```json
{"type": "card", "id": "cd1", "title": "AC Maintenance", "tone": "neutral", "action": { ... }, "children": [ ... ]}
```
0–12 children. `title` ≤ 64. `tone` as above. `action` makes the whole card
tappable.

### `button`
```json
{"type": "button", "id": "b1", "label": "View appointment", "variant": "primary", "intent": "standard", "size": "small", "icon": "fa-solid fa-eye", "enabled": true, "action": { ... }}
```
- `label` **required**, ≤ 64. `action` **required**.
- `variant`: `primary` | `secondary` | `outline` | `transparent` — default `primary`
- `intent`: `standard` | `warning` | `destructive` | `neutral` — default `standard`
- `size`: `block` | `large` | `small` — default `block`. Use `small` for buttons
  inside a card or row; `block` fills the width.
- **If the action is not supported, the entire button disappears.** Only emit
  actions from §5.

### `chip`
```json
{"type": "chip", "id": "ch1", "label": "Popular", "tone": "info", "selected": false, "icon": "fa-solid fa-star", "action": { ... }}
```
`label` **required**, ≤ 40. An unsupported action leaves the chip as a static
label rather than removing it.

### `list` / `list_item`
```json
{"type": "list", "id": "l1", "variant": "plain", "emptyText": "No results", "children": [
  {"type": "list_item", "id": "li1", "title": "Order #1042", "subtitle": "Delivered",
   "leadingIcon": "fa-solid fa-box", "badge": {"label": "Done", "tone": "success"},
   "trailingText": "AED 120", "action": { ... }}
]}
```
- `list` children must all be `list_item`; 1–20 of them.
- `list_item.title` **required** ≤ 64; `subtitle` ≤ 2000; `trailingText` ≤ 64;
  `badge.label` ≤ 40; `leadingImage` is `{"assetId": "..."}`.

### `progress` / `loading`
```json
{"type": "progress", "id": "p1", "value": 0.65, "label": "Booking progress"}
{"type": "loading",  "id": "lo1", "label": "Checking availability"}
```
`progress.value` is 0–1; omit it for indeterminate. Labels ≤ 64.

---

## 5. Actions

```json
{"type": "open_service", "serviceId": "svc_123"}
```

**The SANAD client implements exactly six actions.** Anything else is dropped.

| `type` | Required | Use for |
|---|---|---|
| `send_message` | `text` | Suggested replies — posts `text` as if the user typed it |
| `open_service` | `serviceId` | Open a service |
| `open_appointment` | `appointmentId` | Open an appointment |
| `open_branch` | `branchId` | Open a branch |
| `open_document` | `documentId` | Open a document |
| `copy_text` | `text` | Copy a reference number, code or address |

**Do not emit** `open_url` or `open_route`. They exist in the protocol but no
SANAD client implements them; a node using either is dropped.

Extra scalar params are carried through. Nested objects are not (except
`open_route.params`, which is unusable here anyway).

Maximum 12 actions per message.

---

## 6. Semantic components (5)

**Prefer these over rebuilding the same thing from primitives.** A
`service_card` is smaller to emit, always matches the app's design, and keeps
working when the design changes. Rebuilding one from `row`/`column`/`text` will
look wrong and is explicitly discouraged.

These five are the complete semantic set in v1. There are no provider-side
semantic components.

Structured values are sent **structured**; the app formats them for the
reader's language, currency conventions and clock. Never pre-format a price, a
date or a distance into prose.

### `service_card`
```json
{
  "type": "service_card",
  "id": "s1",
  "serviceId": "svc_123",
  "title": "AC Maintenance",
  "subtitle": "Same-day service",
  "price": {"amount": 100, "currency": "AED"},
  "ratingValue": 4.5,
  "image": {"assetId": "service_tools"},
  "badge": {"label": "Popular", "tone": "info"},
  "action": {"type": "open_service", "serviceId": "svc_123"},
  "fallbackText": "AC Maintenance — 100 AED"
}
```
Required: `serviceId`, `title`. `currency` must be a 3-letter ISO-4217 code.
`ratingValue` 0–5.

### `appointment_card`
```json
{
  "type": "appointment_card",
  "id": "a1",
  "appointmentId": "apt_123",
  "title": "AC Maintenance",
  "startsAt": "2026-09-02T06:00:00Z",
  "whereText": "Downtown branch",
  "status": "Confirmed",
  "statusTone": "success",
  "action": {"type": "open_appointment", "appointmentId": "apt_123"},
  "fallbackText": "AC Maintenance, 2 September at 10:00 AM"
}
```
Required: `appointmentId`, `title`, `startsAt`. **`startsAt` must be ISO-8601,
preferably UTC** — the app converts to the device's timezone and formats it.
Never send "tomorrow at 10". `status` ≤ 40.

### `branch_card`
```json
{
  "type": "branch_card",
  "id": "b1",
  "branchId": "br_1",
  "name": "Downtown",
  "addressText": "Sheikh Zayed Road",
  "distanceMeters": 450,
  "status": "Open",
  "statusTone": "success",
  "action": {"type": "open_branch", "branchId": "br_1"},
  "fallbackText": "Downtown — 450 m — Open"
}
```
Required: `branchId`, `name`. `distanceMeters` is a number **in metres** — the
app decides whether to show "450 m" or "4.8 km".

### `document_card`
```json
{
  "type": "document_card",
  "id": "d1",
  "documentId": "doc_1",
  "title": "Trade licence",
  "status": "Expiring soon",
  "statusTone": "warning",
  "action": {"type": "open_document", "documentId": "doc_1"},
  "fallbackText": "Trade licence — expiring soon"
}
```
Required: `documentId`, `title`, `status`.

### `quick_reply`
```json
{
  "type": "quick_reply",
  "id": "q1",
  "options": [
    {"label": "Yes, book it", "action": {"type": "send_message", "text": "Yes, book it"}},
    {"label": "Pick another time", "action": {"type": "send_message", "text": "Pick another time"}}
  ]
}
```
**2–6 options.** Fewer than two valid options drops the node. `label` ≤ 40.

---

## 7. `fallbackText` — always set it on semantic nodes

An installed app may be older than the agent. When a client meets a node type it
does not know:

- with `fallbackText` → it renders that text, and the user still gets the answer;
- without it → the node vanishes silently.

So: **every semantic node, and every node type introduced after v1.0, must carry
a `fallbackText` that conveys the same information as prose.** This is the whole
backward-compatibility mechanism — there is no capability negotiation.

---

## 8. Limits

| Limit | Value | If exceeded |
|---|---|---|
| Payload size | 32 KB (UTF-8) | **Whole payload rejected** |
| Nodes per message | 100 | **Whole payload rejected** |
| Nesting depth | 6 | Subtree dropped |
| `blocks` | 12 | Truncated |
| `column`/`card` children | 12 | Truncated |
| `row` children | 8 | Truncated |
| `list` children | 20 | Truncated |
| `rich_text` spans | 20 | Truncated |
| `quick_reply` options | 2–6 | Truncated / dropped |
| `text`, `subtitle` | 2000 chars | Truncated |
| Labels, titles, `alt` | 64 chars | Truncated |
| Chip/badge/status labels | 40 chars | Truncated |
| Actions per message | 12 | Extras unusable |
| Images per message | 4 | Extras dropped |

Keep payloads small. A chat reply is one bubble on a phone, not a page.

---

## 9. Choosing primitives vs semantic components

| Situation | Use |
|---|---|
| Showing a service, appointment, branch or document the user can open | the matching **semantic card** |
| Offering 2–6 suggested replies | `quick_reply` |
| A short explanation | `text` |
| Explanation with one emphasised phrase or an inline link | `rich_text` |
| A small labelled group with a call to action | `card` + `text` + `button` |
| A homogeneous set of rows that are not one of the four entities | `list` + `list_item` |
| Anything not covered above | `column` / `row` of primitives |

Do **not** rebuild a service/appointment/branch/document card out of primitives.

---

## 10. Valid example — mixed reply

```json
{
  "schemaVersion": 1,
  "blocks": [
    {"type": "text", "id": "t1", "text": "Your appointment is confirmed."},
    {
      "type": "appointment_card",
      "id": "a1",
      "appointmentId": "apt_123",
      "title": "AC Maintenance",
      "startsAt": "2026-09-02T06:00:00Z",
      "whereText": "Downtown branch",
      "status": "Confirmed",
      "statusTone": "success",
      "action": {"type": "open_appointment", "appointmentId": "apt_123"},
      "fallbackText": "AC Maintenance, 2 September at 10:00 AM, Downtown branch"
    },
    {
      "type": "row",
      "id": "r1",
      "gap": "sm",
      "children": [
        {"type": "button", "id": "b1", "label": "Reschedule", "variant": "outline", "size": "small",
         "action": {"type": "open_appointment", "appointmentId": "apt_123"}},
        {"type": "button", "id": "b2", "label": "Cancel", "variant": "outline", "intent": "destructive", "size": "small",
         "action": {"type": "send_message", "text": "Cancel my appointment"}}
      ]
    }
  ]
}
```

---

## 11. Invalid examples

Each of these fails. The reason is what to internalise.

**String schema version — rejects the whole payload.**
```json
{"schemaVersion": "1", "blocks": []}
```

**Flutter widget names — the type is unknown, the node vanishes.**
```json
{"type": "Container", "padding": 17, "child": {"type": "text", "text": "hi"}}
```

**Markdown as UI — this is one text node containing punctuation, not a table.**
```json
{"type": "text", "text": "| Service | Price |\n|---|---|\n| AC | 100 |"}
```

**Executable intent — not representable; the node is dropped.**
```json
{"type": "button", "label": "Delete", "onTap": "deleteAccount()"}
```

**Unsupported action — the whole button disappears.**
```json
{"type": "button", "label": "Open offer", "action": {"type": "open_url", "url": "https://example.com"}}
```

**Remote image — rejected for every host.**
```json
{"type": "image", "url": "https://cdn.trysanad.us/ac.jpg", "alt": "AC unit"}
```

**Raw colours and pixels — ignored; use `tone` and `gap`.**
```json
{"type": "text", "text": "Warning", "color": "#FF0000", "fontSize": 18}
```

**Pre-formatted price and date — works, but wrong in Arabic. Send structured.**
```json
{"type": "service_card", "serviceId": "s1", "title": "AC", "subtitle": "AED 100.00 · Tomorrow 10:00 AM"}
```

**One quick reply — the node is dropped; a minimum of two is required.**
```json
{"type": "quick_reply", "options": [{"label": "OK", "action": {"type": "send_message", "text": "OK"}}]}
```

**Missing `alt` — the image is dropped.**
```json
{"type": "image", "assetId": "service_tools"}
```

---

## 12. Language and direction

- Send **final, already-localized** text in the user's language. The app does not
  translate payload text.
- Arabic is the default language and RTL is the default direction. Layout mirrors
  automatically — never try to compensate with alignment.
- Mark inherently-LTR values with `"direction": "ltrValue"`.
- Do not format currencies, dates, times or distances into prose. Send `price`,
  `startsAt` and `distanceMeters` structured.

---

## 13. Self-check before emitting

1. Is `schemaVersion` the integer `1`?
2. Is every `type` one of the 20 documented?
3. Is every action one of the **six** the client implements?
4. Does every semantic node carry a `fallbackText`?
5. Is every image an `assetId` — no `url` anywhere?
6. Is every required field present (`text`, `label`, `alt`, `title`, entity ids,
   `startsAt`)?
7. Are prices, instants and distances structured rather than prose?
8. Does `quick_reply` have at least two options?
9. Is the payload under 32 KB and 100 nodes?
10. Is there any Flutter code, Markdown table, or callback anywhere? There must
    not be.

## 14. The inbound turn — what the client sends you

Everything above describes what you send the app. This is the other direction.

```json
{
  "conversation_id": "conv_1",
  "message": "what does this say?",
  "attachments": [
    { "id": "68f1…", "url": "https://…" },
    { "id": "9ab2…", "url": "https://…", "type": "audio",
      "transcript": "book me a plumber for tomorrow morning" }
  ]
}
```

| Field | Presence | Meaning |
|---|---|---|
| `conversation_id` | always | Stable for the visit |
| `message` | always | What the user typed. May be `""` |
| `attachments` | only when the turn carries files | Never sent as `[]` |
| `attachments[].id` | always | Opaque upload id |
| `attachments[].url` | always | Already-resolved location |
| `attachments[].type` | audio only | `"audio"` |
| `attachments[].transcript` | audio, when there is one | Client-side device STT |

### Rules

- **The URL is pre-resolved. Do not look storage up by `id`.** The client
  uploaded the file and already knows where it landed; a second lookup on your
  side is latency for nothing. `id` is there for correlation, logging and any
  later operation that genuinely needs the record.
- **An attachment object carries nothing else.** No file name, MIME type, size,
  local path, duration or waveform. Those describe a file you have a URL for.
- **`transcript` is the words, produced on the device.** When it is present,
  use it. Do not transcribe the audio again as part of the normal flow — that
  is duplicated work on a turn the client already paid for. Re-reading the
  audio is for cases that explicitly need it (tone, speaker, a transcript you
  have concrete reason to distrust), not for routine text reasoning.
- **`transcript` is best-effort and never authoritative.** It comes from the
  device's own recogniser, which may be absent, may have lost the microphone to
  the recorder, or may have misheard. Absent is normal, partial is possible.
  An audio attachment with no `transcript` is speech you have not been given
  words for — not an opaque blob to read as text.
- **When the user typed nothing and there is a transcript, `message` repeats
  it.** Deliberate redundancy: it means a voice note is understood by a reader
  that only looks at `message`. Treat them as one utterance, not two.
- **When the user typed a caption *and* recorded a note, they are different
  things.** `message` is what they wrote; the transcript is what they said. Do
  not merge or discard either.
- **Ignore fields you do not recognise.** The client adds keys additively.
