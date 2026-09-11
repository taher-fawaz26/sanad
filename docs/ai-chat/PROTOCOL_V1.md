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
| `url` | string | no | See §4.1. At least one of `url` / `assetId` must be usable, or the node is dropped. |
| `assetId` | string | no | See §4.1. |
| `aspect` | enum | no | `wide`. One of `square`, `wide`, `thumb`. |
| `fit` | enum | no | `cover`. One of `cover`, `contain`. |

### 4.1 The image object — one shape everywhere

```text
image
 ├── url      optional String, preferred
 └── assetId  optional String, controlled local fallback

Priority:  url > assetId > the node's own no-image state
```

**Every** image in the protocol is this object: the `image` primitive (whose
`url`/`assetId` sit directly on the node), `list_item.leadingImage`,
`service_card.image`, `provider_card.image`, `permission_request.image`,
`location_confirm.image`. There is no second image model anywhere, and no node
has its own image rules.

| Input | Client behaviour |
|---|---|
| `{"url": "https://cdn…/x.jpg"}` | Renders from the network |
| `{"assetId": "service_tools"}` | Renders the bundled asset |
| both present | **Renders the URL.** The asset is the render-time fallback if the download fails; it never overrides a usable URL. |
| `{"url": "", "assetId": "…"}` | Renders the asset — an empty string is "no url", not a broken one |
| `url` refused by the image policy | Diagnostic, then falls through to `assetId`; if there is none, the field is empty |
| `{"assetId": "random_unknown_id"}` | `unknown_asset_id` diagnostic, resolves to nothing |
| `{"url": null, "assetId": null}` | The node's no-image state |

**`url`** is for dynamic, backend-owned media — a service photo, a provider
portrait, business artwork. It is checked against the host's **image URL
policy** during validation: https only, no embedded userinfo, parseable, and
(when the host configures one) a host allowlist. A refused URL never reaches a
widget and never causes a request. The client loads it through its existing
cached-network-image stack, with the app's own loading shimmer and failure
placeholder.

**`assetId`** is **not** an arbitrary string. It names one entry in a small
catalog the *client* publishes; the host hands that catalog to the validator,
and an id outside it is dropped. The ids the SANAD client publishes today
(`AiAssetResolver.defaults()`, whose keys feed `AiUiValidator.knownAssetIds`):

| `assetId` | What it is |
|---|---|
| `image_placeholder` | Generic image placeholder (SVG) |
| `empty_state` | Empty-state illustration |
| `service_tools` | Service / tools illustration |
| `no_branch_locations` | No-branches illustration |
| `ai_map_preview` | Map illustration for the location prompts |

Publishing a new id is a client release, so the list is agreed with the Flutter
team rather than assumed. The agent knows only the canonical
id — never a Flutter asset path, a package path, an Android or iOS resource
name, a filename, or any other local reference. There is no field in which such
a value means anything.

The client is the source of truth for what an id maps to. Changing the file
behind `service_tools` is a client release; the id does not change.

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
| `leadingImage` | object | no | The image object of §4.1 — `{url?, assetId?}` |
| `badge` | object | no | `{"label": ≤40, "tone": enum default neutral}` |
| `trailingText` | string | no | ≤ 64 |
| `action` | action | no | |

### `progress`
`value` number 0–1 (clamped), optional — absent means indeterminate and renders
an activity indicator instead of a bar. `label` optional (≤ 64).

### `loading`
`label` optional (≤ 64).

---

## 5. Semantic nodes (17)

A semantic node names a **business meaning**, and the client owns everything
about how it looks. Seventeen of them cover the current design language; the
Figma component frame they are drawn from is `7998:34166` in file
`al9Mb5tuJN5t4z0GBgrfDG`. All are client-domain — there are no provider-domain
semantic components.

Structured values are sent structured and formatted by the client in the
device's locale — the agent never formats a currency, an instant, or a distance.

Adding a semantic type is additive and does **not** bump `schemaVersion`
(§9). Older clients degrade a type they do not know through `fallbackText`,
which is why every semantic node should carry one.

### 5.0 What every semantic node shares

| Field | Type | Req | Notes |
|---|---|---|---|
| `id` | string | **yes** | Unique within the payload. |
| `fallbackText` | string | no | ≤ 2000. What an older client renders instead. |
| `a11yLabel` | string | no | ≤ 64. Overrides the node's derived screen-reader label. |
| `actions` | array | no | 0–3 card actions, drawn as a row inside the card's own border. |

An `actions` entry is `{"label": ≤40 (R), "action": action (R), "variant"?, "intent"?}`
using the same `button variant` / `button intent` vocabularies as the `button`
primitive. An entry whose action is unresolvable — not in the catalog, or not
in the host's `supportedActions` — is **dropped like a `button`**; the card
survives. A dead control is worse than a missing one.

`actions` is accepted by every semantic node **except** `quick_reply`,
`time_slots`, `review_request` and `location_picker`, which own their own
controls. Sending it there emits `invalid_property` and the array is ignored.

### 5.1 Entity cards

#### `service_card`
| Field | Type | Req | Limits |
|---|---|---|---|
| `serviceId` | string | **yes** | |
| `title` | string | **yes** | ≤ 64 |
| `subtitle` | string | no | ≤ 2000 |
| `price` | object | no | `{"amount": number, "currency": 3-letter ISO-4217}`. Malformed → price dropped, card kept. |
| `ratingValue` | number | no | 0–5, clamped |
| `image` | object | no | The image object of §4.1. Dynamic service artwork belongs in `url`. Rendered as a thumbnail above the title when present. |
| `badge` | object | no | `{"label", "tone"}` |
| `selected` | bool | no | Default `false`. Marks the service the conversation is currently about. |
| `action` | action | no | Whole-card tap. |

#### `appointment_card`
`appointmentId` **required**, `title` **required** (≤ 64), `startsAt`
**required** — ISO-8601, normalised to UTC; unparseable drops the node.
Optional: `whereText` (≤ 2000), `status` (≤ 40), `statusTone` (default
`neutral`), `action`.

#### `branch_card`
`branchId` **required**, `name` **required** (≤ 64). Optional: `addressText`
(≤ 2000), `distanceMeters` (number, 0–40 000 000), `status` (≤ 40),
`statusTone` (default `neutral`), `hoursText` (≤ 64 — "Closes 9:00 PM", already
localized prose because only the backend knows the calendar), `action`.

#### `order_card`
`orderId` **required**, `title` **required** (≤ 64 — the reference as the user
recognises it, "Order #1042"). Optional: `statusText` (≤ 64), `status` (≤ 40)
+ `statusTone` (default `neutral`), `amount` (Money), `action`.

Several stacked `order_card` blocks are what the design calls an order-tracking
dashboard. There is no list type for it: a list of one still has to look right.

#### `provider_card`
`providerId` **required**, `name` **required** (≤ 64). Optional: `roleText`
(≤ 64), `ratingValue` (0–5, clamped), `image` (§4.1 — a portrait is dynamic
media, so send a `url`; the card falls back to a person glyph), `stats` (0–4
entries of `{"label": ≤40, "value": ≤40}` — chip-length, because they sit in a
two-column strip), `action`.

#### `document_card`
`documentId` **required**, `title` **required** (≤ 64), `status` **required**
(≤ 40). Optional: `statusTone` (default `neutral`), `action`.

**Supported — not in the current Figma set.** It is an already-published
contract, so it keeps working and keeps its renderer. Nothing new should be
designed around it; use `order_card` or a summary for new work.

### 5.2 Summaries

#### `booking_summary`
`items` **required**: 1–8 detail items. Optional: `title` (≤ 64).

A detail item is `{"label": ≤64 (R), "value": ≤64 (R), "valueTone"?, "isLtrValue"?}`.
`isLtrValue` marks a value that must not be reordered by an RTL line — a
reference id, a card number, a phone number.

#### `request_summary`
`items` **required** (1–8 detail items). Optional: `summaryTitle` (≤ 64),
`summaryText` (≤ 2000 — the agent's recap in prose), `location`
(`{"label"?: ≤64, "addressText": ≤64 (R), "action"?}`).

#### `payment_receipt`
`title` **required** (≤ 64), `items` **required** (1–8 detail items).
Optional: `subtitle` (≤ 64), `statusTone` (default `success` — `error` for a
failed payment), `total` (`{"label": ≤64 (R), "amount": Money (R)}`).

### 5.3 Interactive nodes

These four own their input state **client-side**. The user's choice travels
back in two halves:

1. the **sentence**, built from a template the agent supplied and posted in the
   turn's `message` — indistinguishable from typing, and the only thing a
   backend that has not implemented results needs to read;
2. the **structured result**, an `interaction` object naming the node, the
   choice and the message that asked. See §13.

Both are sent together, on the same request. The agent still receives text it
authored and never a value it can execute; what the second half adds is that it
no longer has to re-parse its own prose to find out *which* slot was picked.

A template may carry exactly one placeholder — `{comment}`, `{slot}` or
`{location}` as listed below — and the client substitutes the user's own value
and nothing else. A template with no placeholder is sent verbatim.

#### `quick_reply`
`options` **required**: 2–6 entries of `{"label": ≤40, "action": action}`.
Excess truncated; fewer than 2 *valid* options drops the node.

An option whose action is `send_message` also produces a
`quick_reply_selected` result carrying the option's label. An option with any
other action is navigation, not an answer, and produces no result. Picking one
option retires the rest — a set of suggested replies is one choice.

#### `time_slots`
`slots` **required**: 2–12 entries of `{"id" (R), "label": ≤40 (R),
"enabled"?: bool default true}`. `confirmLabel` **required** (≤ 40).
`confirmTemplate` **required** (≤ 2000, placeholder `{slot}` — filled with the
chosen slot's **label**). Optional: `dateLabel` (≤ 64), `selectedSlotId`
(must name one of the slots; an unknown id is ignored).

#### `review_request`
`serviceName` **required** (≤ 64), `submitLabel` **required** (≤ 40),
`submitTemplate` **required** (≤ 2000, placeholder `{comment}`). Optional:
`providerText` (≤ 64), `commentPlaceholder` (≤ 64), `maxCommentLength`
(1–500, clamped; the agent may lower the cap, never raise it).

#### `location_picker`
`title` **required** (≤ 64), `confirmLabel` **required** (≤ 40),
`confirmTemplate` **required** (≤ 2000, placeholder `{location}` — filled with
the chosen place's **name**, or with what the user typed). Optional:
`searchPlaceholder` (≤ 64), `useCurrentLabel` (≤ 40 — renders a row that
requests `request_location_share`), `savedLabel` (≤ 40), `savedLocations` (0–6
entries of `{"id" (R), "name": ≤64 (R), "addressText": ≤64 (R), "icon"?}`).

**One of `useCurrentLabel` or a non-empty `savedLocations` is required.** A
picker that offers neither is a dead end, and the node is dropped: the
conversation is a better place to ask than a card with nothing to choose.

### 5.4 Prompt cards

#### `permission_request`
`permission` **required** — one of `camera`, `photos`, `microphone`,
`location`, `notifications`; an unrecognised value **drops the node** (a
prompt for an unknown capability has no correct button). `title` **required**
(≤ 64), `allowLabel` **required** (≤ 40). Optional: `body` (≤ 2000), `image`
(§4.1 — usually the client's own `ai_map_preview` illustration), `denyLabel`
(≤ 40).

Allow dispatches `request_permission` with the same `permission`; the app runs
the platform prompt and returns a `permission_result` (§13) carrying the
outcome. Deny still collapses the card client-side — the `dismiss` action is
not needed for it — but **also** returns a `permission_result` with
`status: "cancelled"` and `outcome: "denied"`.

That change matters: before results existed, a declined permission ended in a
snackbar the agent never heard about, so it could only carry on as if the
answer had been yes.

#### `media_request`
`title` **required** (≤ 64), `options` **required**: 1–4 entries of
`{"label": ≤64 (R), "source"?: camera|gallery|video|document, default gallery}`.
Optional:
`body` (≤ 2000), `cancelLabel` (≤ 40 — collapses the card, client-side).

Each option dispatches `request_image_upload` carrying its `source`. The app
still owns the permission prompt, the picker and the right to refuse.

The files themselves arrive as the next turn's `attachments`, unchanged — they
are not duplicated into a result. `cancelLabel` returns a `media_result` with
`status: "cancelled"` and `count: 0`, so a user who backs out is not silently
indistinguishable from one who is still choosing.

#### `location_confirm`
`title` **required** (≤ 64), `addressText` **required** (≤ 2000),
`confirmLabel` **required** (≤ 40). Optional: `image` (§4.1 — a real static
map for the place belongs in `url`; the client's `ai_map_preview` asset is the
sensible `assetId`, and a tinted block is the no-image state), `changeLabel`
(≤ 40 — requests `request_location_share` again).

Confirm posts `addressText` back as a user turn **and** returns a
`location_confirmed` result carrying it as a structured place, so accepting a
proposed address is distinguishable from someone typing the same words.
`changeLabel` dispatches `request_location_share` again.

#### `reminder_card`
`title` **required** (≤ 64), `body` **required** (≤ 2000). Optional:
`subtitle` (≤ 64), `tone` (default `warning`).

---

## 6. Actions

```json
{ "type": "open_service", "serviceId": "svc_123" }
```

Fourteen action types are defined by the protocol:

| `type` | Required params | Implemented by the SANAD client |
|---|---|---|
| `send_message` | `text` | yes |
| `open_service` | `serviceId` | yes |
| `open_appointment` | `appointmentId` | yes |
| `open_branch` | `branchId` | yes |
| `open_document` | `documentId` | yes |
| `copy_text` | `text` | yes |
| `request_location_share` | — | yes |
| `request_image_upload` | — (optional `source`) | yes |
| `request_permission` | `permission` | yes |
| `call_phone` | `phone` | yes |
| `open_map` | `query` — an address or `"lat,lng"`, never a URL | yes |
| `open_route` | `routeKey` — a **symbolic key**, never a path | **no** |
| `open_url` | `url` — gated by `AiUiUrlPolicy` (https + host allowlist) | **no** |
| `dismiss` | — | **no** |

The `request_*` actions grant the agent **no** device access. They state an
intent; the app owns the permission prompt, the picker and the decision to
refuse. Emitting one is a request, never a capability. `call_phone` opens the
dialer **pre-filled** — the user always sees the number and still has to press
call — and `open_map` takes a bounded query rather than a URL, which is what
lets `open_url` stay deny-all.

#### Three categories, by what a tap means

The catalog is one enum, but the actions fall into three groups and it is worth
being able to tell at a glance which a given action is:

| Category | Actions | What happens |
|---|---|---|
| **Continuation** | `send_message` | Posts a user turn. The conversation advances. |
| **Client / system** | `open_service`, `open_appointment`, `open_branch`, `open_document`, `copy_text`, `call_phone`, `open_map`, `open_route`, `open_url`, `dismiss` | Something happens on the device. The agent hears nothing back. |
| **Capability** | `request_permission`, `request_image_upload`, `request_location_share` | The app runs a flow it owns, then returns a **result** (§13) — but only when the request came from a node. |

The third row is the one that changed. A capability request that originates
from a semantic node carries two client-added params so its asynchronous
outcome can be matched to the question:

| Param | Meaning |
|---|---|
| `nodeId` | The node whose control was tapped. |
| `messageId` | The assistant message that carried the node. |

**The client adds these, not the agent.** A bare `button` with a
`request_permission` action asked no question, so it carries neither and
produces no result — the outcome is a device interaction with nothing to be the
answer *to*.

Additional scalar params (string, number, bool) are carried through as strings.
Non-scalar params are dropped with a diagnostic. `open_route` additionally
accepts a nested `"params"` object of scalars.

**Two independent gates.** An action must be in the protocol catalog *and* in
the host's `supportedActions` set. The SANAD client implements the eleven
marked above. `open_url` and `open_route` are not implemented — the client has
no URL allowlist configured and no symbolic route map — and `dismiss` is not
implemented because every card that can be dismissed does it itself, without
asking the app. A payload using any of the three has the owning node dropped.

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
| `actions` per semantic node | 3 | Truncated |
| Detail items per summary/receipt | 1–8 | Truncated / node dropped |
| `time_slots.slots` | 2–12 | Truncated / node dropped |
| `location_picker.savedLocations` | 6 | Truncated |
| `media_request.options` | 1–4 | Truncated / node dropped |
| `provider_card.stats` | 4 | Truncated |
| `review_request` comment length | 500 | Clamped (the agent may ask for less) |
| `text.text`, `list_item.subtitle` | 2000 | Truncated |
| Labels, titles, `alt` | 64 | Truncated |
| Chip/badge/status labels | 40 | Truncated |
| Actions per message | 12 | Further actions unresolvable |
| Images per message | 8 | Further images dropped |
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
| Reserved property (`textKey`, `textArgs`) | Ignored / node dropped | `reserved_property` |
| `image.url` refused by the image policy | Falls through to `assetId`, else empty | `invalid_property` |
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
- **Either direction is possible.** English is the product default
  (`AppLanguage.defaultLanguage`) and Arabic is a first-class RTL locale, so a
  payload must read correctly in both. `start`/`end` are visual and flip
  automatically; the protocol has no `left`/`right`.
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
      "id":  String,           // always — the upload id
      "url": String            // always — the resolved location
    }
  ],
  "interaction":     { … }     // only when the turn IS an answer — see §13
}
```

> **Retired capability.** AI Chat used to send recorded voice notes: an
> audio attachment with `type: "audio"` and the on-device `transcript` its
> recogniser produced. That capability was removed as a product decision.
> The client's one voice input is now **Speech-to-Text**: speech is
> converted to text on the device and submitted as an ordinary text
> message, so it arrives in `message` like anything the user typed. **No
> audio attachment is generated, uploaded or serialized, and the agent will
> never receive one from this client.**

### Rules

1. **`attachments` is omitted when empty**, never sent as `[]`. This is what
   makes a text-only turn byte-identical to the two-field body of protocol
   v1.0, so this addition is not a protocol bump and the existing
   request-shape tests hold unchanged. Do not "tidy" it into always emitting
   the key.
2. **An attachment object has exactly `id` and `url`.** Every attachment,
   with no type discriminator and no per-type extras. Nothing else is sent —
   no file name, MIME type, size or local path. The URL is already resolved,
   so the agent performs no storage lookup, and no device path ever leaves
   the phone.
3. **There is no audio attachment, and this client cannot produce one.**
   Speech-to-Text is the only voice input: it yields editable composer text
   that travels in `message`. Do not add a `type` or `transcript` field here,
   and do not expect one — `ai_chat_turn_payload_test.dart` asserts that the
   encoded body contains no audio vocabulary at all.
4. **`message` is passed through as given, including empty.** It is empty
   only for a turn that genuinely has no words — an image or document with no
   caption. Note that the live agent answers an empty `message` with `200`
   and zero frames (see `ARCHITECTURE.md` §3), so such a turn is met with
   silence until the backend learns to read `attachments`. A dictated turn is
   never affected: its words *are* `message`.
5. **`message` is untrimmed.** Trimming happens once, in `AiChatBloc`; doing
   it again here would silently change a pinned body.
6. **Nothing credential-shaped is ever in the body.** The session token is a
   header (`Sanad-Access-Token`) on both transports.
7. **`interaction` is omitted unless the turn is an answer**, by the same rule
   and for the same reason as `attachments`. When it *is* present, `message`
   still carries the sentence the agent's template produced — so a backend that
   ignores `interaction` receives exactly the body a tapped card has always
   sent. See §13.

### Why Speech-to-Text needs no protocol of its own

Because it produces text, and the protocol already carries text. The recogniser
writes into the composer as the user speaks; when it lets go, the words are
ordinary editable content that the user can correct before sending. By the time
a turn is encoded there is nothing to distinguish it from one that was typed —
which is precisely the property that let the recorded-audio contract be deleted
rather than versioned.

---

## 13. The interaction result (client → agent)

Normative for the **client**. `AiUiInteraction` + `AiUiInteractionCodec` in
`packages/ai_ui_protocol` are the only things that build this, and
`ai_ui_interaction_round_trip_test.dart` / `ai_ui_interaction_codec_test.dart`
pin every rule below.

> **Implementation status.** The client emits this today, on every transport.
> **The backend does not read it yet.** Because `message` still carries the
> agent's own sentence, an agent that ignores `interaction` behaves exactly as
> it did before this section existed — which is what makes adopting it a
> backend change that can happen whenever, with no client release to
> coordinate. See `BACKEND_TICKET.md`.

### 13.1 Why it exists

The interactive cards have always answered — as prose, via `send_message` with
a template placeholder filled in. What that cannot carry is *which* node was
answered, *which* message asked, or whether the answer already arrived. An
agent holding only `"Book me the 9:00 AM slot"` has to re-parse its own
sentence to recover a slot id it published thirty seconds earlier.

Three interaction classes could not answer at all: a permission outcome, a
declined permission, and a cancelled prompt all ended in client-side UI the
agent never heard about.

### 13.2 Shape

```
{
  "interactionId": String,   // always — client-minted idempotency key
  "nodeId":        String,   // always — AiUiNode.id
  "nodeType":      String,   // when known — a node type wire value
  "messageId":     String,   // when known — the message that asked
  "kind":          String,   // always — see 13.3
  "status":        String,   // always — submitted | cancelled | failed
  "value":         { ... },  // always — shape implied by `kind`, see 13.4
  "text":          String,   // when there is one — the sentence in `message`
  "createdAt":     String    // when set — UTC ISO-8601
}
```

A worked example, in the turn body it travels in:

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
    "text": "Book me the 9:00 AM slot",
    "createdAt": "2026-09-08T09:14:03.000Z"
  }
}
```

### 13.3 Kinds

| `kind` | Produced by | `value` |
|---|---|---|
| `quick_reply_selected` | `quick_reply` (a `send_message` option) | Selection |
| `slot_selected` | `time_slots` confirm | Selection |
| `review_submitted` | `review_request` submit | Text |
| `location_selected` | `location_picker` confirm | Location |
| `location_confirmed` | `location_confirm` confirm | Location |
| `permission_result` | `permission_request`, `request_permission`, `request_location_share` | Permission |
| `media_result` | `media_request` cancel | Media |

### 13.4 Value shapes

The value carries **no discriminator of its own** — `kind` implies it. That is
what keeps a result from being two things at once.

| Shape | Fields |
|---|---|
| **Selection** | `label` (R), `id` (when the agent published one) |
| **Text** | `text` (R; **may be empty** — an empty review is an answer) |
| **Location** | `name` (R), `source` (R: `saved` or `typed`), `id`, `addressText` |
| **Permission** | `permission` (R — the capability wire value), `outcome` (R: `granted`, `denied`, `permanently_denied`, `unavailable`, `cancelled`) |
| **Media** | `count` (R), `source` |
| **Empty** | `{}` — a cancellation whose meaning is fully carried by `kind` and `status` |

`outcome` is deliberately **not** a platform permission status. Nothing in it
names an Android or iOS concept, so the agent reasons about "may I proceed"
rather than about a plugin's vocabulary.

**Location carries no coordinates.** The client resolves a place from the
agent's own `savedLocations` or from what the user typed, and reads no device
position — `request_location_share` therefore returns
`outcome: "unavailable"`. That is a real answer: the agent can ask the user to
name the place instead of waiting for a fix that is not coming. A
coordinate-bearing variant is additive when a device-location capability
exists.

### 13.5 Correlation

Three identifiers, only one of them new:

- **`nodeId`** — `AiUiNode.id`, which the agent supplied or the validator
  derived from the node's path in the document (§3).
- **`messageId`** — the `AiChatEvent` that delivered the node. Absent during
  live voice, which has no assistant messages, only a session.
- **`conversation_id`** — on the turn body that wraps the result (§12), not
  repeated here.

**`interactionId`** is the only genuinely new one, and it exists for
idempotency: a key has to be minted by the client *before* the request leaves,
so a retry is recognisable as the same answer. It is opaque; nothing parses it.

### 13.6 Lifecycle and duplicate submission

Each node moves through:

```text
active ──► pending ──► submitted
  │           │
  ▼           ▼
cancelled   failed ──► active
```

A submission is refused unless the node is `active` or `failed`. That is the
single place a double tap is stopped — not per widget — and it is why a second
Confirm sends nothing while the first is still in flight.

A **failed** send returns the node to answerable. A dropped request must never
leave the user looking at a control they cannot use and cannot explain.

`expired` and `superseded` are deliberately **not** modelled: nothing in the
protocol carries a TTL, and an older card staying answerable in a scrollback is
the honest behaviour. The agent is the only party that knows whether a late
answer is still useful, which is what `messageId` is for.

### 13.7 `text`, and who writes it

**The agent's template wins where there is one; the client supplies the words
where there is not.**

An interactive card has a template — `"Book me the {slot} slot"` — so `text` is
that template with the user's value substituted, and the agent can never be
made to post words it did not author. A permission outcome has no template,
because no agent wrote "you declined"; that is client copy, in the user's
language, and `text` is filled from the app's own translations.

Either way the sentence and the structured result travel together, and the
conversation reads like something a person said.

### 13.8 Error handling

| Situation | Behaviour |
|---|---|
| Second tap, or a tap while a send is in flight | Refused by the lifecycle. Nothing is sent. |
| Send fails | Node becomes `failed`, controls return, the transport's existing error surfaces. |
| Nothing selected yet | Confirm stays disabled — no template is posted with an empty substitution. |
| User declines | A result **is** sent, with `status: "cancelled"`. Silence would be indistinguishable from a broken client. |
| Unknown `kind` or `status` on decode | The result is ignored. An unreadable `status` is never assumed to be `submitted`. |
| Value of the wrong shape | Degrades to `{}`, keeping the result — that the user answered is worth more than the payload it came with. |
| Voice session ends with a card up | The card is taken down and the node returns to `active`; no result is sent, because there is no session to send it to. |
| Free text over the limit | Clamped to `maxInteractionTextLength` (2000) by the encoder. |

### 13.9 Live voice

The same object, over a different wire. A voice session's semantic channel
delivers an ordinary `{schemaVersion, blocks}` payload and accepts an ordinary
interaction result back; the node definitions, the value shapes, the lifecycle,
the validation and the renderer are one implementation shared with chat.

Two differences, both of them transport-shaped:

1. **No `messageId`.** There are no assistant messages in a session, so
   `nodeId` alone identifies the question.
2. **The session waits.** While a card is up the session is in
   `awaitingInteraction` and the microphone is released, so silence detection
   and barge-in cannot race a user reading a question.

> **Implementation status.** The client-side contract above is implemented and
> tested. **There is no realtime voice backend**: the semantic beats are
> supplied by a local script (`MockVoiceScenarios`), and the assistant's audio
> is the user's own capture played back. What is *not* mocked is the path a
> card takes — validation, rendering, the ledger, the interaction and the
> session's state machine are the real ones.
