# ADR-0009: A Bespoke Semantic UI Protocol for AI Chat

**Date:** 2026-08-31
**Status:** Accepted (v1, prototype)
**Deciders:** Platform Architecture Team

## Context

The SANAD AI assistant must return more than prose: cards, buttons, lists and
business-domain components rendered natively inside the chat. Three constraints
shaped the decision.

1. **AI output is untrusted input.** It must not be able to execute code,
   navigate freely, reach arbitrary hosts, or crash the chat.
2. **The design system must stay ours.** `.claude/rules/ui.md` forbids a parallel
   design system, and the look must keep evolving without a protocol or prompt
   change.
3. **The protocol must outlive its transport and its shell.** Swapping the mock
   for a WebSocket, or the chat shell for something else, must not require
   redesigning rendering.

The existing repo offered no starting point: no chat UI, no streaming transport
(`BaseApiClient.request<T>()` returns `TaskEither` and cannot express a
`Stream`), and no server-driven UI of any kind. The one relevant precedent was
`BackendIconResolver` — backend sends a string, client resolves it, unknown
returns `null`, never throws — which the whole renderer now follows.

## Decision

Define **SANAD Chat UI Protocol v1**: a closed, versioned, *semantic* JSON
vocabulary, implemented across two new packages.

- **`packages/ai_ui_protocol` (tier 0)** — models, codec, validator, limits,
  diagnostics. **No Flutter dependency in its pubspec**, so a parsed payload
  cannot reach a `Widget`, a route or the network.
- **`packages/ai_ui_renderer` (tier 3)** — the only layer that can act on a
  payload: renderer registry, action registry, resolvers, design-token mapping.

Key properties:

- 15 primitives and 5 client-domain semantic components. The agent names
  *intent* (`service_card`), never Flutter layout (`Container`, `Padding`).
- Style is a closed enum vocabulary (`tone`, `emphasis`, `gap`) mapped to design
  tokens. Hex colours, pixel values and font names are not representable.
- Actions are declarative objects from a fixed catalog, dispatched through a
  compile-time `Map<AiUiActionType, AiActionHandler>` — no string-to-method
  dispatch, no reflection, no eval.
- The validator's allowlists are **derived from the app's registries**, so an
  action with no handler is dropped before a widget exists.
- Parse once at ingestion; renderers are total functions over validated data.
- Images are `assetId`-only in v1 — no remote URLs, for any host.
- `fallbackText` is the entire backward-compatibility mechanism; no capability
  negotiation.

We also build our **own thin chat shell** rather than adopting a chat package,
behind a seam that keeps swapping one in cheap.

## Consequences

### Positive
- The audit question "what can an AI payload reach?" has one small answer, and
  the dependency graph enforces it.
- The design system can change without touching the protocol or the prompt.
- Transport, shell and renderer are independently replaceable.
- A malformed or hostile payload degrades one bubble; the chat continues.

### Negative
- We own the schema, the validator and every renderer — roughly 20 node types to
  maintain, and any new component needs work on both sides.
- The agent can only express what the catalog admits. Genuinely novel layouts
  need a protocol change and a client release.
- A registry rather than a sealed `switch` gives up compile-time exhaustiveness
  (mitigated by a test asserting every node type has a renderer).

### Risks
- Catalog drift between the docs and the code — mitigated by generating the docs
  from the extracted field lists and keeping `AI_CONTRACT.md` a strict subset of
  the validator.
- Older installed clients silently dropping newer components — mitigated by
  requiring `fallbackText` on every semantic node.

## Alternatives Considered

| Option | Reason rejected |
|---|---|
| **`rfw`** (flutter.dev) | Renders **arbitrary widget trees** from a remote DSL — the agent would author Flutter layout, not intent. README has no security section despite executing remote UI descriptions. |
| **`stac`, `json_dynamic_widget`, `serve_dynamic_ui`** | Same problem: JSON→widget mappers exposing `Container`/`Padding`/`Expanded`. |
| **`genui`** (labs.flutter.dev) | Closest in spirit — catalog + JSON schema + builder — but alpha with declared breaking changes, and its reactive `DataModel` binding layer is far more machinery than a chat bubble needs. |
| **Markdown as the UI transport** | Cannot express actions or business identity; would make every card a parsing problem. Retained only as a possible future *text* format. |
| **`flutter_chat_ui` as the shell** | `flutter_chat_core` pulls in `dio` and `provider` — both restricted by our own rules — ships its own `ChatTheme`/`ChatColors`/`ChatTypography` (a parallel design system), and its `Message` type is a sealed freezed union we cannot extend, so our typed document would have to live in `CustomMessage.metadata` as an untyped map. |
| **`flutter_gen_ai_chat_ui`** | Own message model and theme; `google_fonts` fetches assets at runtime. |
| **`flutter_ai_toolkit`** | Assumes Firebase AI; markdown-centric rendering. |

### Prior art we aligned with but did not adopt

Google's **A2UI** (Apache-2.0, v0.9, April 2026) converges on the same shape:
an agent emits JSON referencing a **host-advertised catalog**, and the host
renders with **native widgets**, transport-agnostic. We shaped the v1 catalog to
resemble its basic set (`Text`, `Image`, `Icon`, `Row`, `Column`, `List`, `Card`,
`Divider`, `Button`, with semantic style hints rather than raw values) so a
future bridge is a mapping exercise rather than a redesign.

One A2UI choice we deliberately did **not** copy: a flat component list with ID
references, which streams a large surface better. Our payloads are one chat
bubble, where a nested tree is simpler to validate and read. Recorded as a v2
consideration.

## Transport addendum — 2026-09-05

The consequences section above notes that `BaseApiClient.request<T>()` returns
`TaskEither` and cannot express a `Stream`, and that this is why the transport
went WebSocket. That reasoning still holds for `BaseApiClient`; the conclusion
has changed.

The agent team could not supply a complete WebSocket integration contract, so
the real transport moved to a **streamed `POST`** —
`POST /user-agent/chat/stream`, `text/event-stream` — implemented as
`SseAiChatEventSource`. This decision is **temporary and transport-only**.

What made it cheap, and what it validates:

- The endpoint already emits the Protocol v1 envelope verbatim. There is **no
  adapter and no mapping layer**: each `data:` frame goes straight to the
  existing `AiChatEventCodec`.
- Nothing above `AiChatEventSource` changed — not the bloc, the protocol, the
  validator, the renderer, the action registry or the message-state design.
  The seam did the job it was built for.
- `WebSocketAiChatEventSource` is **retained**, reachable with
  `?transport=ws`. `MockAiChatEventSource` is untouched.

`BaseApiClient` was **not** widened. It has no `Options`, `ResponseType` or
`CancelToken`, and a `TaskEither` yields one value; adding a stream-returning
method would touch every implementer and leak Dio types past the boundary this
ADR's consequences set. The agent also lives on a different host and
authenticates with a raw `Sanad-Access-Token` rather than `Authorization:
Bearer`, so `NetworkDI`'s interceptor stack does not apply. The transport
therefore owns a small, interceptor-free Dio behind an injectable connector
seam, inside the feature — `packages/network` is unchanged.

One consequence the transport swap surfaced: the endpoint emits **no `ui`
event**, so prose is the only channel, and it is Markdown-heavy. The chat bubble
now renders assistant prose through `AiUiMarkdown` — the same helper the `text`
node renderer already used. Markdown *prose* remains acceptable; Markdown
standing in for structure remains forbidden (`AI_CONTRACT.md` §0.2).

## Follow-ups

- Transport: revisit the WebSocket once the agent team can supply a contract;
  the source is still there. ~~Replace `MockAiChatEventSource` with a WebSocket
  source.~~ Done, then superseded by SSE — see the addendum above.
- Wire a real diagnostics sink — `analytics` is currently a dependency of
  nothing and `ErrorReporter.use(...)` is never called.
- Decide whether `open_url` gets a host allowlist, and whether v2 admits remote
  images.
- Golden tests, once the repo has golden infrastructure.
