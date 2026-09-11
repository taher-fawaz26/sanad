# AI Chat — Architecture

How the SANAD AI chat prototype is put together, and why the seams are where
they are. Describes the code as it exists today.

Related: [`PROTOCOL_V1.md`](PROTOCOL_V1.md) (the wire contract),
[`AI_CONTRACT.md`](AI_CONTRACT.md) (agent-facing rules),
[`../features/ai-chat.md`](../features/ai-chat.md) (feature walkthrough),
[`../adr/0009-ai-chat-ui-protocol.md`](../adr/0009-ai-chat-ui-protocol.md)
(why this shape and not an off-the-shelf one).

---

## 1. Layers

```text
        SseAiChatEventSource            ← live transport (POST + SSE, authenticated)
   WebSocketAiChatEventSource            ← reference transport (`?transport=ws`)
        MockAiChatEventSource            ← scripted transport (`?mock=1`)
                 │  implements AiChatEventSource
                 ▼
   apps/sanad_client/lib/src/features/ai_chat/          (app-local, tier 7)
     domain/        AiChatMessage · AiChatEventSource
     data/          SseAiChatEventSource · SseFrameParser
                    WebSocketAiChatEventSource
                    MockAiChatEventSource · mock_scenarios
     presentation/  AiChatBloc + ActiveStreamController
                    AiChatScreen → AiChatPage → AiChatBubble/Composer
                    ai_chat_action_handlers
     ai_chat_config.dart   URL policy · supported actions · validator factory
                 │
                 │  AiUiDocument (already parsed and validated)
                 ▼
   packages/ai_ui_renderer                              (tier 3, Flutter)
     AiUiHost/AiUiSurface → AiUiRendererRegistry → AiNodeRenderer → App* widgets
     rendering/renderers/       text · layout · interactive · media
     rendering/renderers/semantic/  entity_cards · summaries · interactive · prompts
     rendering/primitives/      AiSemanticCard · card content · prompt parts
     AiActionRegistry → AiActionHandler → app code
     AiAssetResolver · AiIconResolver · AiUiTokens · AiCardTokens · AiUiFormatters
     AiUiDiagnosticsSink
                 │
                 ▼
   packages/ai_ui_protocol                              (tier 0, PURE DART)
     AiUiCodec · AiUiValidator (+ validation/parsers/) · AiUiLimits · AiUiUrlPolicy
     AiUiDocument · AiUiNode (sealed, + domain/nodes/) · AiUiAction · AiUiDiagnostic
     AiChatEvent (sealed) · AiChatEventCodec
```

Tiers are enforced by [`dep_rules.yaml`](../../dep_rules.yaml) and
`melos run validate:deps --strict`.

---

## 2. The load-bearing boundary

`ai_ui_protocol` declares **no dependency on Flutter**. Not by convention — by
`pubspec.yaml`. Its only dependencies are `equatable` and `meta`.

A payload parsed there therefore *cannot* reference a `Widget`, a `Color`, an
`IconData`, a route or the network, because none of those types are reachable
from the package. "AI output is untrusted data, not code" is a property of the
dependency graph rather than a rule someone has to remember.

Everything that can *act* on a payload lives in `ai_ui_renderer`, which is small
and auditable. The question "what can an AI payload reach?" has one answer, in
one place.

---

## 3. Transport seam

```dart
abstract class AiChatEventSource {
  Stream<AiChatEvent> get events;
  Future<void> send(String text);
  Future<void> dispose();
}
```

Three members, and three implementations that share nothing but this interface.
Nothing above the interface knows the difference — the bloc, the renderer and
the protocol are all transport-agnostic. Adding the socket source changed no
bloc, renderer or protocol code; **replacing it with the SSE source changed none
either**, which is the claim this seam existed to make good on.

| Source | Reached by | Role |
|---|---|---|
| `SseAiChatEventSource` | a plain visit | The current real transport |
| `WebSocketAiChatEventSource` | `?transport=ws` | Reference transport, kept intact |
| `MockAiChatEventSource` | `?mock=1` | Scripted scenarios, including hostile payloads |

### The live transport — POST + SSE

`POST https://agent-<env>.trysanad.us/user-agent/chat/stream`.

**Why not the socket.** Temporary. The agent team could not supply a complete
WebSocket contract, and this endpoint already emits the Protocol v1 envelope
verbatim. The socket source is retained, not deleted.

- **One request per turn**, not one connection per visit. A new turn cancels the
  one in flight rather than racing it.
- Sends `{"conversation_id": …, "message": …}` — the same body the socket
  sends — plus an `attachments` array when the turn carries files (see
  **Attachments on the wire** below; the key is absent otherwise).
  `conversation_id` is stable for the visit, and the server keeps its own
  conversation memory across turns (verified live: turn 2 recalled turn 1).
- **Authentication** is the existing `TokenManager` — the same one the REST
  stack uses. The access token goes in the `Sanad-Access-Token` request header
  and nowhere else: never in the body (where it would reach the model), never in
  a log, a diagnostic or an error message. It is re-read each turn, so a
  mid-conversation refresh is picked up. There is no second token store and no
  separate auth flow.
- A missing token is not fatal: the server accepts the request and the agent
  simply loses its authenticated tools. Failing closed here would turn a
  degraded chat into no chat.
- **No interceptors.** The agent is a different host from the REST API and uses
  a raw `Sanad-Access-Token`, so `AuthInterceptor` is the wrong component — and
  its 401 retry re-issues with `Dio.fetch`, handing us a second stream while we
  consume the first. `RetryOnTimeoutInterceptor` would duplicate text on a
  partly-consumed stream, and `LoggingInterceptor` has no `ResponseBody` case.
- **Timeouts** are a dedicated 15s connect / 60s receive. In streaming mode
  Dio's receive budget is *inter-chunk*, and the measured worst
  time-to-first-token on dev was 9.3s — the shared 15s default leaves no
  headroom.

#### Observed wire format

`data: ` + one line of JSON, blank-line delimited, bare LF. No `event:`, no
`id:`, no `retry:`, no comment/keepalive lines, no `[DONE]` sentinel; the stream
simply closes. `SseFrameParser` handles all of that, plus CRLF and a lone CR,
because the spec allows them even though this server does not use them.

Bytes are decoded with **one streaming `Utf8Decoder` per turn**. Decoding each
network chunk independently would corrupt any multi-byte sequence straddling a
boundary — a real hazard for Arabic, and the reason the parser test sweeps every
byte split position.

#### The three invented events

Errors do not arrive as SSE: a bad request is a normal `422` with a JSON body,
*before* any stream. So the transport synthesises a local `error` event — and
only ever for these:

| Code | When |
|---|---|
| `connection_failed` / `http_<status>` | the request never opened, or returned non-2xx |
| `timeout` | connect or inter-chunk budget exhausted |
| `stream_interrupted` | `message_start` arrived but `message_end` never did |

A non-2xx contributes **its status code only**. The body is an internal
(Pydantic) error document and never reaches a diagnostic or the user.

One case deliberately invents nothing: a `200` that closes with zero frames —
reproducible by sending an empty `message` — opens no bubble, so it is reported
as a diagnostic and emits no event.

The envelope model and its codec live in `ai_ui_protocol`, not in the feature,
precisely so both transports and a second app can share them.

---

### Attachments on the wire

A turn that carries files sends them as `{id, url}` pairs, uploaded before the
request is made. The agent is handed the **resolved location**, so it never
performs a storage lookup to find a file the client can already point at.

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

`AiChatTurnPayload` (`data/ai_chat_turn_payload.dart`) is the single place this
is shaped, shared by both transports so they cannot drift. Its rules and the
reason for each are in `PROTOCOL_V1.md`; the load-bearing one is that
**`attachments` is omitted when empty**, which is why a text turn is
byte-identical to the two-field body this endpoint has always received.

#### Where the upload happens, and why not here

`POST <env>-api.trysanad.us/api/v1/media/upload-single` — the REST host, through
`packages/media_upload` and its `SecureDioClient`.

It cannot ride the agent's own Dio. Two hosts, two auth schemes: the agent takes
a raw `Sanad-Access-Token` header and deliberately runs with no interceptors
(see above), while the upload needs Bearer auth, refresh and retry. Routing the
upload through `SecureDioClient` is what keeps this change from introducing a
second upload or auth system.

The seam is `AiAttachmentUploader` (`domain/services/`), a sealed-result port in
the same shape as `AiAttachmentSource`; `MediaUploadAiAttachmentUploader`
(`data/platform/attachments/`) is the only file in the feature that names
`media_upload`. A transport constructed without one gets the `const`
`AiUnavailableAttachmentUploader`, which succeeds trivially for an empty batch —
that default is what let both transports gain the capability without touching a
single existing construction site.

Uploads happen **at send time**, inside `sendMultimodal`, not eagerly at pick
time. `AiChatBloc` adds the user's bubble *before* calling the transport, so the
turn appears instantly and only the reply waits; and nothing is uploaded that
the user then removes — which matters, because `DELETE /media/{id}` is
provider-only and the client cannot withdraw an orphan.

A batch is **all or nothing**. The first failure abandons the rest, no request
is made, and one `AiChatErrorEvent` carrying `ai_chat.attachment_upload_failed`
reaches the existing snackbar. Nothing is lost: the typed text is already in
the user's own bubble, and the picked files stay where the picker put them.

#### Why upload identity is a wrapper, not a field

`AiUploadedAttachment { source, mediaId, url }` wraps an `AiChatAttachment` for
the duration of one send. The attachment itself still carries no backend field,
because it lives in `AiChatMessage.attachments` for the life of the
conversation while an upload id is valid for one request — and because a
message's `props` include its attachments, a mutable backend field there would
re-emit the whole message list every time an upload resolved.

#### Speech is text, and only text

An attachment object is exactly `id` and `url`, with no discriminator and no
per-type extras. There is no audio attachment: **AI Chat does not send recorded
audio.**

It used to. A held microphone produced an AAC file, a waveform and an
`AiAudioAttachment` carrying the transcript its own device recogniser captured
during the take, and the wire had `type: "audio"` plus `transcript` for it. That
capability was **retired as a product decision** and removed rather than
disabled — model, serialization, recorder, playback, gesture, state machine and
all.

What replaced it is simpler than a contract: `AiComposerBloc`'s one microphone
capability is speech recognition, whose results go to
`SpeechTranscriptController` and from there into the composer's text field as
the user speaks. When the recogniser lets go the words are ordinary editable
text. By encode time a dictated turn is byte-identical to a typed one, which is
why no protocol addition was needed and why the old one could simply be
deleted. `ai_chat_turn_payload_test.dart` pins that no audio vocabulary can be
serialized at all.

## 4. Parse once, at ingestion

`AiChatBloc` validates a `ui` event the moment it arrives and stores the
resulting `AiUiDocument` on the message. No widget ever sees raw JSON.

Consequences:

- no `build()` pays for decoding, on any frame;
- a malformed payload is a *state* the UI renders, never an exception it must
  survive;
- renderers are total functions over validated data, so they contain no
  defensive parsing.

## 5. Validator and renderer share their allowlists

```dart
AiChatConfig.validator(keepUnsupportedNodes: !kReleaseMode)
// urlPolicy       : AiUiUrlPolicy.denyAll
// supportedActions: AiChatConfig.supportedActions   (6 actions)
// knownAssetIds   : AiAssetResolver.defaults().publishedIds
```

The action set the validator enforces is the same set the action registry
implements, and the asset ids it accepts are the ones the resolver can resolve.
That is what makes "a button that renders always does something" true rather
than hopeful: an action with no handler is dropped *before* a widget exists.

A test asserts the registry's keys equal `AiChatConfig.supportedActions`.

In `ai_ui_renderer`, `validatorFor(environment)` does the same derivation for
any other host.

---

## 6. Streaming without rebuilding the conversation

The requirement: a token must not rebuild the message list.

```text
text_delta ──► AiChatBloc ──► ActiveStreamController (ValueNotifier<String>)
                   │                     │
              (no emit)          ValueListenableBuilder
                                          │
                                  the active bubble only
```

`AiChatBloc` emits a list-level state only when a message is **added,
completed, or fails**. `text_delta` calls `activeStream.append(delta)` and
returns without emitting. Only the streaming bubble listens to the notifier, so
exactly one widget rebuilds per token.

Supporting details: `ListView.builder(reverse: true)`, `ValueKey(message.id)`,
a `RepaintBoundary` per row, `Equatable` messages, and a `buildWhen` that only
fires on list-shaped changes.

Two tests pin this: one asserts 0 bloc states across a burst of deltas
(`ai_chat_bloc_test.dart`), one asserts the streaming bubble updates while a
completed sibling is untouched (`ai_chat_widget_test.dart`).

---

## 7. Renderer registry

```dart
abstract class AiNodeRenderer<T extends AiUiNode> {
  Widget render(BuildContext context, T node, AiUiRenderScope scope);
  Widget build(BuildContext context, AiUiNode node, AiUiRenderScope scope);
}
```

`AiUiRendererRegistry` maps `AiUiNodeType` → renderer, plus a separate
`fallbackRenderer` slot for `AiUiUnsupportedNode` (whose `type` is `null` by
definition and so cannot be keyed).

A registry rather than a `switch` over the sealed hierarchy is a deliberate
trade: we give up compile-time exhaustiveness to gain the ability to override
one node type without editing a central file. A test restores the lost safety by
asserting every protocol node type has a default renderer.

`AiUiRenderScope` carries the registry, action dispatcher, resolvers,
diagnostics sink and depth **down the tree by constructor**. `AiUiSurface` reads
the `AiUiHost` environment exactly once per surface, so drawing a 100-node tree
does no per-node ancestor lookups.

## 8. Design-system mapping

`AiUiTokens` is the only place protocol vocabulary becomes SANAD tokens:
`tone` → `context.appColors` roles, `style`/`emphasis` → `context.appTypography`,
`gap`/`spacing` → `AppSpacing`, `variant`/`intent`/`size` → the real
`AppButton*` enums.

Nodes render as `AppButton`, `AppChip`, `AppSectionCard`, `AppEntityListItem`,
`AppStatusBadge`, `AppDivider`, `AppProgressBar`, `AppLoadingIndicator`,
`AppSvgPicture` and `FaIcon`. There is no parallel theme.

`AiUiFormatters` renders structured values (`price`, `startsAt`,
`distanceMeters`, `ratingValue`) in the device locale via `intl`, using the
repo's explicit 12-hour `DateFormat('h:mm a')` convention.

`ai_ui_renderer` does **not** depend on `localization`. The few display strings
it needs come in through `AiUiStrings`, injected by the host, so a presentation
library does not force a translation bootstrap on every consumer.

---

## 9. Action architecture

```text
AiUiAction ──► AiActionRegistry (Map<AiUiActionType, AiActionHandler>) ──► app code
```

Built at DI time. No string-to-method dispatch, no reflection, no eval. The
registry's key set is handed to the validator (§5), so an unregistered action is
unreachable.

The client registers six handlers. `open_url` and `open_route` are deliberately
absent: there is no symbolic route map yet, and registering `open_url` would let
the agent send the user off-app.

Prototype handlers for the four `open_*` actions surface the resolved intent as
a snackbar, because the destination screens do not exist in `sanad_client` yet.
Replacing each with `context.push(ClientRoutes.…)` is a one-line change.

---

## 10. Security model

| Threat | Mitigation |
|---|---|
| Code execution | Protocol is pure Dart data. No eval, no reflection, no widget DSL. |
| Arbitrary navigation | `open_route` takes a symbolic key, and is not implemented anyway. Raw paths are not representable. |
| Arbitrary network | Images are `assetId`-only in v1; `image.url` is rejected for every host. `open_url` is gated by `AiUiUrlPolicy` **and** unimplemented. |
| Token / storage access | The protocol and renderer have no `storage`, `network` or `auth` dependency — by pubspec, not by policy. |
| Destructive actions | Six allowlisted actions; each handler is app code that owns its own authorization. |
| Resource exhaustion | `AiUiLimits` enforced before any widget is built. |
| Crash-as-DoS | Total parse/validate; renderers operate on validated types; per-subtree try/catch. |
| PII in logs | Diagnostics carry code + path + node type only, capped at 120 chars — never payload prose. |

---

## 11. Diagnostics

`AiUiDiagnosticsSink` receives everything the client refused to render.
`LoggingAiUiDiagnosticsSink` routes to `appLogger`, and renderer failures
additionally to `ErrorReporter.report(..., fatal: false)` — the seam an app
swaps for a crash backend at bootstrap.

Known prototype limitation: `appLogger` filters below `warning` in release and
`ErrorReporter.use(...)` is not wired in `sanad_client`, so today diagnostics are
effectively debug-only.

---

## 12. Failure behaviour

An invalid or hostile payload degrades the **bubble**, never the chat.

| Situation | Result |
|---|---|
| Unknown node with `fallbackText` | renders as plain text |
| Unknown node without it | dropped (release) / labelled marker (dev) |
| Unhandled action on a button | whole button dropped — a dead control is worse than a missing one |
| Unhandled action on a chip | chip stays, tap removed |
| Remote image URL | rejected at validation; no request is issued |
| Limits exceeded | truncate or reject per the protocol |
| A renderer throws | that subtree renders nothing; `renderer_failure` reported |

The `try`/`catch` in `AiUiRenderScope.renderChild` catches throws during **widget
construction**, not during layout or paint. An app wanting to survive those too
should scope an `ErrorWidget.builder` around its chat page.

---

## 13. Prototype boundaries

Deliberately absent, and not stubbed:

- conversation history across visits
- conversation persistence
- analytics wiring
- production authentication
- production route exposure — `AiChatModule` registers `/dev/ai-chat` only when
  `!kReleaseMode`, so the path does not exist in a release build

---

## 14. The interaction layer — one contract, two transports

### 14.1 What it replaced

The interactive cards were already half of a loop. `time_slots`,
`review_request`, `location_picker` and `quick_reply` owned their input state
and answered by dispatching `send_message` with a template placeholder filled
in — the agent's own sentence, posted as an ordinary user turn.

What that could not carry was identity. The agent received
`"Book me the 9:00 AM slot"` and had to recover `s_0900` — an id it had
published seconds earlier — by parsing its own prose. And three interaction
classes could not answer at all:

| Before | Where it ended |
|---|---|
| `permission_request` → allow/deny | A snackbar. The agent was never told. |
| `request_location_share` | A "capability unavailable" snackbar. |
| `media_request` | The composer's picker; files arrived later, uncorrelated. |

Live voice had no semantic channel of any kind: `AiVoiceSession` exposed a
status stream, a level stream, and a failure key.

### 14.2 The shape of the change

```text
                    ai_ui_protocol  (tier 0, no Flutter)
                    ├── AiUiNode / AiUiAction        AI → client
                    └── AiUiInteraction + values     client → AI
                                  │
                    ai_ui_renderer (tier 3)
                    ├── AiUiSurface / renderers      draws the question
                    ├── AiUiInteractionLedger        node lifecycle
                    └── AiUiInteractionSink          where answers go
                                  │
                    ┌─────────────┴─────────────┐
              AiChatBloc                  AiVoiceSessionBloc
        AiChatBlocInteractionSink       AiVoiceInteractionSink
                    │                             │
      SSE / WebSocket / mock            AiVoiceSession (mock)
      `interaction` on the turn body    session's own channel
```

Everything above the fork is one implementation. The fork is two sinks, each
about ten lines, and two transports. A `time_slots` card does not know which
session it is in, and neither transport knows anything about time slots.

### 14.3 Why the ledger is not widget state, and not bloc state

It was widget state: `_ReviewRequestState._submitted` guarded one of the three
interactive cards, and the other two had no guard at all. That was already
unreliable — answering appends a turn, the conversation list rebuilds, and the
flag did not survive it.

Bloc state is the other obvious home, and it is wrong for the opposite reason:
selecting a time slot would emit a new `AiChatState` and rebuild the whole
conversation. The same reasoning that keeps streaming tokens out of state
(`ActiveStreamController`) applies here.

So `AiUiInteractionLedger` hands out **one `ValueListenable` per node id**.
Answering a card rebuilds exactly the controls that changed. It is owned by the
bloc, so its lifetime is the conversation: a card scrolled out of the list and
back still knows it was answered, and a failed send can re-enable the card it
came from.

### 14.4 Two seams, two directions

`AiActionRegistry` carries the agent's requests *in*. `AiUiInteractionSink`
carries the user's results *out*. Keeping them separate is what makes the
direction of any call obvious at the site, and it is why a result can never be
dispatched as an action.

The capability actions sit between them: `request_permission` and friends go
*in* through the registry, and their outcome comes back *out* through the sink.
The render scope attaches `nodeId` and `messageId` to those dispatches so the
handler can correlate an asynchronous platform outcome with the question that
asked. A bare `button` carrying the same action asks no question and produces
no result — which is exactly its old behaviour.

### 14.5 Backward compatibility, and how it is enforced

`AiUiEnvironment.interactions` defaults to `NoopAiUiInteractionSink`, and
`AiUiRenderScope.submitInteraction` recognises that type and falls back to
dispatching the interaction's prose as a `send_message`. That is precisely what
the cards did before results existed.

This is not a comment; it is the compatibility guarantee, and it is guaranteed
only while something tests it. `semantic/interactive_test.dart` and
`semantic/prompts_test.dart` still run against the no-op sink and still assert
the `send_message` dispatch, unchanged. `interactive_submission_test.dart` runs
the same widgets against a real sink and asserts the structured result. Both
halves are pinned.

On the wire the same discipline applies: `interaction` is omitted when the turn
is not an answer, so a text-only turn is byte-identical to before, and
`message` still carries the sentence when it *is* an answer, so a backend that
has not adopted the field is unaffected.

### 14.6 Live voice: one new state, one new stream

`AiVoiceSession` gained `Stream<AiVoiceEvent> events` and
`submitInteraction(...)`. The status and level streams are untouched — the
level ticks dozens of times a second and stays on its own path to the waveform,
while semantic events arrive once or twice a conversation. Merging them would
put an audio meter and a card on one stream and force every listener to filter.

`AiVoiceSessionStatus.awaitingInteraction` is the only new state, and it exists
because the original eight could not express "a card is on screen and the
assistant is waiting for a tap": `listening` tells the user to speak,
`processing` says the assistant is thinking, `speaking` says it is talking.

Its `capturesAudio` is `false`, which is the substantive part. Leaving capture
running would put silence detection and barge-in in a race with a user reading
a question — a cough would end a turn that had not started.

The card is drawn as an **inline panel** in the voice screen, not a
`SheetNavigator` sheet. A sheet is a route, and a route on top of the voice
route is a second lifecycle that ending the session and backgrounding the app
would each have to remember to dismiss. Drawn inside the screen, the panel
disappears exactly when the state that produced it does.

> **Prototype boundary.** There is still no realtime voice transport. The
> semantic beats come from `MockVoiceScenarios` and the assistant's audio is
> the user's own capture played back. What is *not* mocked is the path a card
> takes: validation, rendering, the ledger, the interaction and the session's
> state machine are the real ones, and a real transport replaces
> `MockAiVoiceSession` without the bloc or the screen changing.
