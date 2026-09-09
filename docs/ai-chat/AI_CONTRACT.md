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
{"type": "image", "id": "im1", "url": "https://cdn.example.com/service.jpg", "alt": "Service photo", "aspect": "wide", "fit": "cover"}
{"type": "image", "id": "im2", "assetId": "service_tools", "alt": "Service tools", "aspect": "wide", "fit": "cover"}
```
- `url` and `assetId` are both optional, but **at least one must be usable** or
  the node is dropped. See §4.1 for the rule that governs every image.
- `alt` **required**, ≤ 64. A node without it is dropped.
- `aspect`: `square` | `wide` | `thumb` — default `wide`
- `fit`: `cover` | `contain` — default `cover`

### 4.1 Images — one rule, everywhere

```text
image
├── url      optional, preferred
└── assetId  optional, controlled local fallback

Priority:  url > assetId > the component's own no-image state
```

**When both exist, the URL wins.** `assetId` never overrides a usable URL — it
is the fallback the app uses if the download fails.

| What you send | What the app does |
|---|---|
| `{"url": "https://cdn…/x.jpg"}` | Loads it, cached, with a loading shimmer |
| `{"assetId": "service_tools"}` | Draws the bundled illustration |
| both | **Loads the URL.** The asset waits as the fallback |
| `{"url": "", "assetId": "…"}` | Draws the asset — an empty string means "no url" |
| a `url` that is not `https://`, or has embedded userinfo | Refused before any request; falls back to `assetId` if you sent one |
| `{"assetId": "something_invented"}` | Nothing. An unpublished id is dropped |
| neither, or both `null` | The component's normal no-image state |

**Send a `url` for anything dynamic** — a service photo, a provider portrait,
business or order artwork. Do not ask for a bundled asset for backend-owned
media; there is no local file for a specific provider's face.

**`assetId` is an allowlist, not a free field.** These are the only valid
values, and each names a static illustration the app ships:

| `assetId` | What it is |
|---|---|
| `image_placeholder` | Generic image placeholder |
| `empty_state` | Empty-state illustration |
| `service_tools` | Service / tools illustration |
| `no_branch_locations` | No-branches illustration |
| `ai_map_preview` | Map illustration for the location prompts |

Anything else resolves to nothing. In particular **never** send a Flutter asset
path (`assets/images/x.png`), a package path (`packages/app_assets/…`), an
Android resource (`@drawable/x`), an iOS resource name, a bare filename, or any
other local reference — the app matches the string against the list above and
nothing else. Ask the mobile team before relying on an id that is not in it;
publishing one is a client release.

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
  `badge.label` ≤ 40; `leadingImage` is the image object of §4.1 — row artwork
  for an order or a service belongs in its `url`.

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

**The SANAD client implements exactly eleven actions.** Anything else is
dropped, along with the button or card that asked for it.

| `type` | Required | Use for |
|---|---|---|
| `send_message` | `text` | Suggested replies — posts `text` as if the user typed it |
| `open_service` | `serviceId` | Open a service |
| `open_appointment` | `appointmentId` | Open an appointment |
| `open_branch` | `branchId` | Open a branch |
| `open_document` | `documentId` | Open a document |
| `copy_text` | `text` | Copy a reference number, code or address |
| `request_location_share` | — | Ask the app to run its own location flow |
| `request_image_upload` | — (optional `source`: `camera`/`gallery`/`video`/`document`) | Ask the app to run its own picker |
| `request_permission` | `permission`: `camera`/`photos`/`microphone`/`location`/`notifications` | Ask the app to request a device permission |
| `call_phone` | `phone` | Open the dialer **pre-filled**. It never dials — the user sees the number and presses call |
| `open_map` | `query` — an address, or `"lat,lng"` | Open the platform maps app at a place |

The four `request_*` / device actions grant you **no** device access. They state
an intent; the app owns the permission prompt, the picker, and the right to
refuse. Emitting one is a request, never a capability.

**Do not emit** `open_url`, `open_route` or `dismiss`. They exist in the
protocol but no SANAD client implements them: there is no URL allowlist, no
symbolic route map, and every card that can be dismissed does it itself. A node
using any of the three is dropped.

`open_map` takes a place, not a link — that is deliberate, and it is why
`open_url` can stay closed.

Extra scalar params are carried through. Nested objects are not (except
`open_route.params`, which is unusable here anyway).

Maximum 12 actions per message.

### 5.1 Buttons attached to a card

Most semantic cards accept an `actions` array — up to three buttons drawn
inside the card's own border:

```json
"actions": [
  {"label": "Reschedule", "action": {"type": "send_message", "text": "Reschedule it"}, "variant": "outline"},
  {"label": "Cancel", "action": {"type": "send_message", "text": "Cancel it"}, "variant": "outline", "intent": "destructive"}
]
```

`label` ≤ 40 and `action` are required; `variant`
(`primary`/`secondary`/`outline`/`transparent`) and `intent`
(`standard`/`warning`/`destructive`/`neutral`) are optional. An entry whose
action is not implemented is dropped on its own — the card and its other
buttons survive.

`quick_reply`, `time_slots`, `review_request` and `location_picker` do **not**
take `actions`: they carry their own controls.

---

## 6. Semantic components (17)

**Prefer these over rebuilding the same thing from primitives.** A
`service_card` is smaller to emit, always matches the app's design, and keeps
working when the design changes. Rebuilding one from `row`/`column`/`text` will
look wrong and is explicitly discouraged.

Structured values are sent **structured**; the app formats them for the
reader's language, currency conventions and clock. Never pre-format a price, a
date or a distance into prose.

Every one of them takes `fallbackText` (§7). Set it.

### 6.1 Entity cards — one thing the user can open

#### `service_card`
```json
{
  "type": "service_card",
  "id": "s1",
  "serviceId": "svc_123",
  "title": "AC Maintenance",
  "subtitle": "Complete system cleaning, filter replacement, and airflow diagnostics.",
  "price": {"amount": 100, "currency": "AED"},
  "ratingValue": 4.5,
  "image": {"url": "https://cdn.example.com/services/ac.jpg", "assetId": "service_tools"},
  "badge": {"label": "Popular", "tone": "primary"},
  "selected": true,
  "actions": [{"label": "Select", "action": {"type": "send_message", "text": "AC Maintenance please"}, "variant": "secondary"}],
  "fallbackText": "AC Maintenance — 100 AED"
}
```
Required: `serviceId`, `title`. `currency` must be a 3-letter ISO-4217 code.
`ratingValue` 0–5. `selected: true` marks the one the conversation is about.
The `image` is the object of §4.1: the service photo belongs in `url`, and the
`assetId` beside it is the fallback if the download fails. The card draws a
thumbnail only when you send one.

#### `appointment_card`
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
  "actions": [
    {"label": "Reschedule", "action": {"type": "send_message", "text": "Reschedule it"}, "variant": "outline"},
    {"label": "Cancel", "action": {"type": "send_message", "text": "Cancel it"}, "variant": "outline", "intent": "destructive"}
  ],
  "fallbackText": "AC Maintenance, 2 September at 10:00 AM"
}
```
Required: `appointmentId`, `title`, `startsAt`. **`startsAt` must be ISO-8601,
preferably UTC** — the app converts to the device's timezone and formats it.
Never send "tomorrow at 10". `status` ≤ 40.

#### `branch_card`
```json
{
  "type": "branch_card",
  "id": "b1",
  "branchId": "br_1",
  "name": "Downtown",
  "addressText": "Sheikh Zayed Road, Dubai",
  "distanceMeters": 450,
  "status": "Open",
  "statusTone": "success",
  "hoursText": "Closes 9:00 PM",
  "fallbackText": "Downtown branch, 450 m away, closes 9:00 PM"
}
```
Required: `branchId`, `name`. Send `distanceMeters` as a number — the app
writes "Distance: 450 m" in the reader's language. `hoursText` is prose you
localize, because only you know the calendar.

#### `order_card`
```json
{
  "type": "order_card",
  "id": "o1",
  "orderId": "ord_1042",
  "title": "Order #1042",
  "statusText": "Delivered",
  "status": "Completed",
  "statusTone": "success",
  "amount": {"amount": 120, "currency": "AED"},
  "fallbackText": "Order #1042 — delivered, 120 AED"
}
```
Required: `orderId`, `title`. Stack several for an order dashboard; there is no
list type for it.

#### `provider_card`
```json
{
  "type": "provider_card",
  "id": "p1",
  "providerId": "prv_9",
  "name": "Ahmed K.",
  "roleText": "AC and plumbing specialist",
  "ratingValue": 4.8,
  "image": {"url": "https://cdn.example.com/providers/ahmed.jpg"},
  "stats": [
    {"label": "Completed jobs", "value": "340+"},
    {"label": "With CleanCo since", "value": "2021"}
  ],
  "actions": [
    {"label": "Call", "action": {"type": "call_phone", "phone": "+971500000000"}, "variant": "outline"},
    {"label": "Message", "action": {"type": "send_message", "text": "Message Ahmed"}}
  ],
  "fallbackText": "Ahmed K., your assigned specialist"
}
```
Required: `providerId`, `name`. Up to 4 `stats`, each label and value ≤ 40.
A portrait is dynamic media, so send it as a `url` — there is no bundled asset
for a specific person, and the card falls back to a person glyph.

#### `document_card`
Still supported, but **not part of the current design set** — prefer
`order_card` or a summary for new work. `documentId`, `title` and `status`
required.

### 6.2 Summaries — several values the user should check

All three take `items`: **1–8** rows of
`{"label": ≤64, "value": ≤64, "valueTone"?, "isLtrValue"?}`. Set
`"isLtrValue": true` on a reference id, card number or phone number so an
Arabic line cannot reorder it.

#### `booking_summary`
```json
{
  "type": "booking_summary",
  "id": "bs1",
  "title": "Booking Summary",
  "items": [
    {"label": "Service", "value": "Deep Cleaning"},
    {"label": "Provider", "value": "CleanCo Marina"},
    {"label": "Estimated Cost", "value": "150 AED", "valueTone": "primary"}
  ],
  "actions": [
    {"label": "Go back", "action": {"type": "send_message", "text": "Go back"}, "variant": "secondary"},
    {"label": "Confirm", "action": {"type": "send_message", "text": "Confirm the booking"}}
  ],
  "fallbackText": "Deep Cleaning with CleanCo Marina, about 150 AED"
}
```

#### `request_summary`
Adds your own recap: `summaryTitle`, `summaryText` (prose), and `location`
(`{"label"?, "addressText", "action"?}`) which renders an address row with an
"open in maps" link when you attach `{"type": "open_map", "query": "…"}`.

#### `payment_receipt`
```json
{
  "type": "payment_receipt",
  "id": "r1",
  "title": "Payment Successful",
  "subtitle": "Thank you for your order",
  "statusTone": "success",
  "items": [
    {"label": "Transaction ID", "value": "TXN-8829410", "isLtrValue": true},
    {"label": "Payment Method", "value": "Apple Pay (•••• 4920)", "isLtrValue": true}
  ],
  "total": {"label": "Amount Paid", "amount": {"amount": 150, "currency": "AED"}},
  "actions": [{"label": "View Receipt", "action": {"type": "send_message", "text": "Show me the receipt"}, "variant": "outline"}],
  "fallbackText": "Payment of 150 AED succeeded"
}
```
`statusTone: "error"` turns it into a declined-payment card.

### 6.3 Interactive components — the user answers inside the card

These four hold the user's input themselves and send you **text** when it is
submitted: a template you supplied, with the user's own value substituted. You
never receive a value you could execute, and the app never sends anything the
user did not choose.

Templates take exactly one placeholder, named below. A template without one is
sent verbatim.

#### `quick_reply`
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

#### `time_slots`
```json
{
  "type": "time_slots",
  "id": "ts1",
  "dateLabel": "Tomorrow, September 3rd",
  "slots": [
    {"id": "0900", "label": "9:00 AM"},
    {"id": "1030", "label": "10:30 AM"},
    {"id": "1400", "label": "2:00 PM", "enabled": false}
  ],
  "selectedSlotId": "0900",
  "confirmLabel": "Confirm Time",
  "confirmTemplate": "Book me the {slot} slot tomorrow",
  "fallbackText": "Available tomorrow: 9:00 AM, 10:30 AM"
}
```
**2–12 slots**, `label` ≤ 40. `enabled: false` for a slot that is already
taken. `{slot}` is filled with the chosen slot's label.

#### `review_request`
```json
{
  "type": "review_request",
  "id": "rv1",
  "serviceName": "Deep Cleaning",
  "providerText": "Provided by CleanCo Marina",
  "commentPlaceholder": "Leave a comment (optional)...",
  "maxCommentLength": 300,
  "submitLabel": "Submit Review",
  "submitTemplate": "Here is my review: {comment}",
  "fallbackText": "How was your Deep Cleaning?"
}
```
`{comment}` is filled with what the user typed. `maxCommentLength` may only
lower the client's own 500-character cap.

#### `location_picker`
```json
{
  "type": "location_picker",
  "id": "lp1",
  "title": "Set your location",
  "searchPlaceholder": "Search for a neighborhood or city...",
  "useCurrentLabel": "Use current location",
  "savedLabel": "SAVED LOCATIONS",
  "savedLocations": [
    {"id": "home", "name": "Home", "addressText": "Dubai Marina, Tower 5, Apt 1204"},
    {"id": "office", "name": "Office", "addressText": "DIFC, The Gate District, Level 4"}
  ],
  "confirmLabel": "Confirm",
  "confirmTemplate": "My location is {location}",
  "fallbackText": "Where should the service happen?"
}
```
Up to 6 saved locations. `{location}` is filled with the chosen place's name,
or with whatever the user typed into the search field.

**Send either `useCurrentLabel` or at least one saved location** — a picker
offering neither is dropped, because there would be nothing to pick.

### 6.4 Prompt cards — asking for something the app owns

#### `permission_request`
```json
{
  "type": "permission_request",
  "id": "pr1",
  "permission": "camera",
  "title": "Allow camera access?",
  "body": "Sanad needs your camera to take photos for this request. You can change this later in settings.",
  "allowLabel": "Allow camera",
  "denyLabel": "Not now",
  "fallbackText": "May Sanad use your camera?"
}
```
`permission` must be one of `camera`, `photos`, `microphone`, `location`,
`notifications` — anything else **drops the card**, because there is no correct
button for a capability the app does not have. Allow asks the app; deny just
closes the card.

#### `media_request`
```json
{
  "type": "media_request",
  "id": "mr1",
  "title": "Add photos or video",
  "body": "Sanad only requests camera or photo access when you choose one of these options.",
  "options": [
    {"label": "Take a photo", "source": "camera"},
    {"label": "Choose photos", "source": "gallery"},
    {"label": "Add a short video", "source": "video"}
  ],
  "cancelLabel": "Cancel",
  "fallbackText": "You can add photos or a short video."
}
```
1–4 options. The app still owns the permission prompt and the picker.

#### `location_confirm`
```json
{
  "type": "location_confirm",
  "id": "lc1",
  "title": "Confirm your location",
  "addressText": "Dubai Marina",
  "confirmLabel": "Confirm location",
  "changeLabel": "Change location",
  "fallbackText": "Is Dubai Marina the right place?"
}
```
Confirm sends `addressText` back as a user turn; change asks the app to run its
location flow again. For the preview: send `{"assetId": "ai_map_preview"}` for
the client's own illustration, or a `url` if you have a real static map of the
place. Omit `image` and the card shows a plain tinted block.

#### `reminder_card`
```json
{
  "type": "reminder_card",
  "id": "rm1",
  "title": "Reminder",
  "subtitle": "AC Maintenance",
  "body": "Your appointment is in 30 minutes. Please make sure someone is home to grant access.",
  "tone": "warning",
  "actions": [
    {"label": "Reschedule", "action": {"type": "send_message", "text": "Reschedule it"}, "variant": "outline"},
    {"label": "I'm ready", "action": {"type": "send_message", "text": "I am ready"}}
  ],
  "fallbackText": "Your AC Maintenance appointment is in 30 minutes."
}
```
`tone` defaults to `warning`; use `error` for something already overdue.

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
| `actions` on a card | 3 | Truncated |
| Summary / receipt `items` | 1–8 | Truncated / dropped |
| `time_slots.slots` | 2–12 | Truncated / dropped |
| `location_picker.savedLocations` | 6 | Truncated |
| `media_request.options` | 1–4 | Truncated / dropped |
| `provider_card.stats` | 4 | Truncated |
| Review comment length | 500 chars | Clamped |
| `text`, `subtitle`, `body`, templates | 2000 chars | Truncated |
| Labels, titles, `alt` | 64 chars | Truncated |
| Chip/badge/status labels | 40 chars | Truncated |
| Actions per message | 12 | Extras unusable |
| Images per message | 8 | Extras dropped |

Keep payloads small. A chat reply is one bubble on a phone, not a page.

---

## 9. Choosing primitives vs semantic components

| Situation | Use |
|---|---|
| A service, appointment, branch, order or provider the user can open | the matching **entity card** |
| Several values the user should check before committing | `booking_summary` |
| The same, plus your own recap and a location | `request_summary` |
| A payment that succeeded or failed | `payment_receipt` |
| Offering 2–6 suggested replies | `quick_reply` |
| Offering specific times to choose from | `time_slots` |
| Asking for a rating or written feedback | `review_request` |
| Asking where the service should happen | `location_picker` |
| Checking an address you already have | `location_confirm` |
| Asking for a photo, a video or a document | `media_request` |
| Asking for a device permission | `permission_request` |
| Warning about something upcoming or overdue | `reminder_card` |
| A short explanation | `text` |
| Explanation with one emphasised phrase or an inline link | `rich_text` |
| A small labelled group with a call to action | `card` + `text` + `button` |
| A homogeneous set of rows that no semantic type covers | `list` + `list_item` |
| Anything not covered above | `column` / `row` of primitives |

Do **not** rebuild one of the seventeen out of primitives: it will not match
the app's design, and it will not keep matching it when the design moves.

Do **not** ask for a component that does not exist by inventing a type name or
a generic `{"type": "custom_card", "data": {...}}`. There is no escape hatch;
an unknown type renders as its `fallbackText` and nothing else.

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

**Insecure image URL — refused before any request.**
```json
{"type": "image", "url": "http://cdn.trysanad.us/ac.jpg", "alt": "AC unit"}
```
https only. With an `assetId` beside it the app shows that instead; without
one, the node is dropped.

**A local path in `url` or `assetId` — resolves to nothing.**
```json
{"type": "image", "assetId": "assets/images/logo.png", "alt": "Logo"}
{"type": "image", "url": "file:///data/data/com.sanad.client/x.png", "alt": "x"}
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
2. Is every `type` one of the 32 documented (15 primitives + 17 semantic)?
3. Is every action one of the **eleven** the client implements?
4. Does every semantic node carry a `fallbackText`?
5. Is every image either a `url` (dynamic media, https) or an `assetId` from
   the published list in §4.1 — and never a local path?
6. Is every required field present (`text`, `label`, `alt`, `title`, entity ids,
   `startsAt`)?
7. Are prices, instants and distances structured rather than prose?
8. Does `quick_reply` have at least two options, and `time_slots` at least two
   slots?
9. Does every template (`confirmTemplate`, `submitTemplate`) carry its one
   placeholder — `{slot}`, `{comment}` or `{location}`?
10. Is the payload under 32 KB and 100 nodes?
11. Is there any Flutter code, Markdown table, or callback anywhere? There must
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

---

## 15. Interaction results — what a tapped card sends you

> **Status: the client sends this today. The backend does not read it yet.**
> Nothing below is required to keep working. Because `message` still carries
> the sentence *you* authored, an agent that ignores `interaction` behaves
> exactly as it did before this section existed. Adopting it is a backend-only
> change. The normative shape is `PROTOCOL_V1.md` §13.

### 15.1 What changed, and why you want it

The interactive cards have always answered you in prose, built from the
template you supplied:

```json
{ "type": "time_slots", "confirmTemplate": "Book me the {slot} slot" }
```

The user picks 9:00 AM, and you receive `"Book me the 9:00 AM slot"` in
`message`. That still happens, unchanged.

What it never told you: **which node** was answered, **which of your messages**
asked, and whether you have already seen this answer. You published
`{"id": "s_0900", "label": "9:00 AM"}` a moment earlier and then had to
recover `s_0900` by matching on your own sentence.

Now the same turn also carries:

```json
{
  "conversation_id": "conv_1",
  "message": "Book me the 9:00 AM slot",
  "interaction": {
    "interactionId": "int_1757..._9f2c",
    "nodeId": "slots_1",
    "nodeType": "time_slots",
    "messageId": "msg_7",
    "kind": "slot_selected",
    "status": "submitted",
    "value": { "id": "s_0900", "label": "9:00 AM" },
    "text": "Book me the 9:00 AM slot"
  }
}
```

`interaction` is **absent** on an ordinary typed turn. Its presence is what
tells you this turn is an answer rather than a new thought.

### 15.2 The kinds you will see

| `kind` | The user | `value` |
|---|---|---|
| `slot_selected` | confirmed a time | `{ "id", "label" }` |
| `review_submitted` | submitted a review | `{ "text" }` — **may be empty** |
| `location_selected` | chose a place in a picker | `{ "name", "source", "id"?, "addressText"? }` |
| `location_confirmed` | accepted an address you proposed | same as above |
| `quick_reply_selected` | tapped a suggested reply | `{ "label" }` |
| `permission_result` | answered a capability request | `{ "permission", "outcome" }` |
| `media_result` | backed out of a media request | `{ "count": 0 }` |

### 15.3 The three things you could not previously know

**1. A refused permission.** Before, "Allow" and "Not now" both ended in
client-side UI you never heard about, so you could only carry on as though the
answer had been yes. Now:

```json
{ "kind": "permission_result", "status": "cancelled",
  "value": { "permission": "camera", "outcome": "denied" } }
```

`outcome` is one of `granted`, `denied`, `permanently_denied`, `unavailable`,
`cancelled`. Branch on it. `permanently_denied` means asking again is pointless
— only the system settings screen can change it. `unavailable` means the
capability does not exist for this client at all.

**Location is the case to read carefully.** `request_location_share` currently
returns `outcome: "unavailable"` — this client reads no device position. That
is a real answer, not an error: ask the user to name the place, or send a
`location_picker`. Do not wait for a fix that is not coming, and do not retry.

**2. A cancellation.** `status: "cancelled"` means the user declined. Say
something and move on. It is deliberately *sent* rather than swallowed,
because an agent that hears nothing cannot tell "the user declined" from "the
client is broken" — and would either wait forever or repeat itself.

**3. An empty answer.** `review_submitted` with `{"text": ""}` is a real
answer: the user submitted without writing. Acknowledge it and continue. Do not
ask again.

### 15.4 Rules

- **`interaction` is additive. Ignoring it is safe.** `message` is unchanged.
- **`text` duplicates `message`.** Same utterance, not two.
- **Prefer `value` over parsing `text`.** `text` is prose for the human reading
  the conversation; `value` is the data. `value.id` is the identifier *you*
  published — resolve by it, never by matching a display label.
- **`text` is not always yours.** Where you supplied a template it is your
  words with the user's value substituted. Where you did not — a permission
  outcome — the client supplies its own localized sentence, because you never
  authored "you declined". Do not assume `text` is a template you wrote.
- **Use `interactionId` for idempotency.** It is minted by the client before
  the request leaves, so a retry carries the same id. Treat a repeat as the
  same answer, not a second one. It is opaque — do not parse it.
- **Use `messageId` to decide whether the answer is still relevant.** The
  client does not expire cards: a user can scroll back and answer a question
  from ten turns ago. You are the only party that knows whether that still
  makes sense.
- **`messageId` is absent during live voice.** A session has no assistant
  messages; `nodeId` alone identifies the question there.
- **Ignore fields and enum values you do not recognise.** The client adds
  additively, exactly as you do.

### 15.5 What has not changed

- Templates are still **required** on the interactive nodes, and still the only
  source of the words a card posts. A card cannot post text you did not author.
- Attachments still arrive as `attachments` (§14). A `media_request` does not
  duplicate the files into `interaction` — only a *cancellation* is reported.
- Display-only nodes, `send_message`, and every existing action behave as they
  always did.
